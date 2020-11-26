import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(Arkanoid());
}

class Arkanoid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arkanoid',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.pressStart2pTextTheme()),
      home: ArkanoidGame(),
    );
  }
}

abstract class GameObject {
  Offset position;
  Size size;

  GameObject({this.position, this.size});

  Widget render(Animation<double> controller, Size unitSize) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Positioned(
            top: position.dy * unitSize.height,
            left: position.dx * unitSize.width,
            width: size.width * unitSize.width,
            height: size.height * unitSize.height,
            child: renderGameObject(unitSize)),
      );

  Widget renderGameObject(Size unitSize);

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

class Ball extends GameObject {
  Offset direction;
  double speed;

  Ball({Offset position, this.direction, this.speed})
      : super(position: position, size: Size(.5, .5));

  @override
  Widget renderGameObject(Size unitSize) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.all(Radius.circular(100.0)),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(100), offset: Offset(10, 10))
          ]),
    );
  }
}

enum PowerUpType { length, balls, speed }

extension PowerUpProps on PowerUpType {
  Color get color {
    switch (this) {
      case PowerUpType.length:
        return Colors.blue;
      case PowerUpType.speed:
        return Colors.red;
      case PowerUpType.balls:
        return Colors.green;
    }
  }

  String get letter {
    switch (this) {
      case PowerUpType.length:
        return "L";
      case PowerUpType.speed:
        return "S";
      case PowerUpType.balls:
        return "B";
    }
  }
}

class PowerUp extends GameObject {
  final PowerUpType type;
  PowerUp({Offset position, this.type})
      : super(position: position, size: Size(2, 1));

  @override
  Widget renderGameObject(Size unitSize) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(type.color, Colors.black, .1),
                  Colors.grey.shade200,
                  type.color,
                  Color.lerp(type.color, Colors.black, .1),
                  Color.lerp(type.color, Colors.black, .2),
                ]),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(100), offset: Offset(10, 10))
            ],
            borderRadius: BorderRadius.all(Radius.circular(16))),
        padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Center(
            child: Text(type.letter,
                style: TextStyle(
                    color: Colors.yellow.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black, blurRadius: 3.0)]))));
  }
}

class Brick extends GameObject {
  Color color;

  Brick({Offset position, this.color})
      : super(position: position, size: Size(2, 1));

  @override
  Widget renderGameObject(Size unitSize) {
    return CustomPaint(painter: BrickPainter(brickColor: color));
  }

  Widget drawShadow(Size unitSize) {
    return Positioned(
        top: position.dy * unitSize.height,
        left: position.dx * unitSize.width,
        width: size.width * unitSize.width,
        height: size.height * unitSize.height,
        child: (Container(
            width: size.width * unitSize.width,
            height: size.height * unitSize.height,
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(100), offset: Offset(10, 10))
            ]))));
  }
}

Paint stroke = Paint()
  ..strokeWidth = 1
  ..color = Colors.black
  ..style = PaintingStyle.stroke;

class BrickPainter extends CustomPainter {
  final Color brickColor;
  final Paint main;
  final Paint light;
  final Paint dark;

  BrickPainter({this.brickColor})
      : main = Paint()
          ..color = brickColor
          ..style = PaintingStyle.fill,
        light = Paint()
          ..color = Color.lerp(brickColor, Colors.white, .1)
          ..style = PaintingStyle.fill,
        dark = Paint()
          ..color = Color.lerp(brickColor, Colors.black, .1)
          ..style = PaintingStyle.fill;
  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    Rect inner = rect.deflate(3);
    canvas.drawRect(rect, main);
    canvas.drawPath(
        Path()
          ..moveTo(inner.left, inner.top)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(inner.right, inner.top)
          ..lineTo(inner.left, inner.top),
        light);
    canvas.drawPath(
        Path()
          ..moveTo(inner.right, inner.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(inner.right, inner.bottom)
          ..lineTo(inner.right, inner.top),
        dark);
    canvas.drawPath(
        Path()
          ..moveTo(inner.left, inner.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(inner.right, inner.bottom)
          ..lineTo(inner.left, inner.bottom),
        dark);
    canvas.drawPath(
        Path()
          ..moveTo(inner.left, inner.top)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(inner.left, inner.bottom)
          ..lineTo(inner.left, inner.top),
        dark);
    canvas.drawRect(rect, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Paddle extends GameObject {
  double speed = 10.0;

  bool left = false;
  bool right = false;

  double desiredLength = 3.0;

  Paddle({Offset position}) : super(position: position, size: Size(3.0, .7));

  @override
  Widget renderGameObject(Size unitSize) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade700,
                  Colors.red.shade300,
                  Colors.red.shade600,
                  Colors.red.shade800,
                ]),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(100), offset: Offset(10, 10))
            ]),
        child: Center(
          child: Container(
              width: (size.width * unitSize.width) * .7,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade300,
                      Colors.grey.shade600,
                      Colors.grey.shade800,
                      Colors.black,
                    ]),
              )),
        ));
  }
}

class ArkanoidGame extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ArkanoidGameState();
}

class _ArkanoidGameState extends State<ArkanoidGame>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  Size worldSize;
  Paddle paddle;
  List<Ball> balls;
  List<Brick> bricks;
  List<PowerUp> powerups;

  int prevTimeMS = 0;

  int score = 0;
  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(days: 99));
    controller.addListener(update);
    worldSize = Size(18.0, 28.0);
    paddle = Paddle(position: Offset(9.0 - 3.0 / 2, 26.0));
    balls = [
      Ball(
          position: Offset(8.3, 18),
          direction: Offset.fromDirection(-.9),
          speed: 9)
    ];
    bricks = [
      Brick(position: Offset(2, 2), color: Colors.green),
      Brick(position: Offset(4, 2), color: Colors.green),
      Brick(position: Offset(6, 2), color: Colors.green),
      Brick(position: Offset(10, 2), color: Colors.green),
      Brick(position: Offset(12, 2), color: Colors.green),
      Brick(position: Offset(14, 2), color: Colors.green),
      Brick(position: Offset(2, 3), color: Colors.red),
      Brick(position: Offset(4, 3), color: Colors.red),
      Brick(position: Offset(6, 3), color: Colors.red),
      Brick(position: Offset(10, 3), color: Colors.red),
      Brick(position: Offset(12, 3), color: Colors.red),
      Brick(position: Offset(14, 3), color: Colors.red),
      Brick(position: Offset(2, 4), color: Colors.amber),
      Brick(position: Offset(4, 4), color: Colors.amber),
      Brick(position: Offset(6, 4), color: Colors.amber),
      Brick(position: Offset(10, 4), color: Colors.amber),
      Brick(position: Offset(12, 4), color: Colors.amber),
      Brick(position: Offset(14, 4), color: Colors.amber)
    ];

    powerups = [PowerUp(position: Offset(4.0, 7.0), type: PowerUpType.balls)];

    prevTimeMS = DateTime.now().millisecondsSinceEpoch;
    controller.forward();
  }

  void update() {
    int currTimeMS = DateTime.now().millisecondsSinceEpoch;
    int deltaMS = currTimeMS - prevTimeMS;
    double deltaS = deltaMS / 1000.0;

    List<Brick> destroyedBricks = [];
    List<PowerUp> consumedPowerups = [];

    if (paddle.desiredLength > paddle.size.width) {
      double growthAmount = .5 * deltaS;
      paddle.size = Size(paddle.size.width + growthAmount, paddle.size.height);
      paddle.position =
          Offset(paddle.position.dx - growthAmount / 2, paddle.position.dy);
    }
    if (paddle.left && paddle.position.dx > 0) {
      paddle.position = Offset(
          paddle.position.dx - paddle.speed * deltaS, paddle.position.dy);
    }
    if (paddle.right &&
        paddle.position.dx + paddle.size.width < worldSize.width) {
      paddle.position = Offset(
          paddle.position.dx + paddle.speed * deltaS, paddle.position.dy);
    }
    Rect paddleRect = paddle.rect;

    for (PowerUp powerup in powerups) {
      powerup.position =
          Offset(powerup.position.dx, powerup.position.dy + 4.0 * deltaS);
      Rect powerupRect = powerup.rect;
      if (paddleRect.overlaps(powerupRect)) {
        consumedPowerups.add(powerup);
        score += 500;
        switch (powerup.type) {
          case PowerUpType.length:
            paddle.desiredLength += 1.0;
            break;
          case PowerUpType.speed:
            paddle.speed += 2.0;
            break;
          case PowerUpType.balls:
            balls.add(Ball(
                position: Offset(paddle.position.dx + paddle.size.width * .5,
                    paddle.position.dy - 1.0),
                direction: Offset.fromDirection(-.5),
                speed: 8.0));
            break;
        }
      }
    }

    for (Ball ball in balls) {
      ball.position = ball.position + ball.direction * ball.speed * deltaS;
      if (ball.position.dx + ball.size.width > worldSize.width) {
        ball.position =
            Offset(worldSize.width - ball.size.width, ball.position.dy);
        ball.direction = Offset(-ball.direction.dx, ball.direction.dy);
      }
      if (ball.position.dx < 0) {
        ball.position = Offset(0, ball.position.dy);
        ball.direction = Offset(-ball.direction.dx, ball.direction.dy);
      }
      if (ball.position.dy < 0) {
        ball.position = Offset(ball.position.dx, 0);
        ball.direction = Offset(ball.direction.dx, -ball.direction.dy);
      }

      Rect ballRect = ball.rect;
      if (paddleRect.overlaps(ballRect)) {
        Rect intersection = ballRect.intersect(paddleRect);
        if (intersection.height < intersection.width &&
            ball.position.dy < paddle.position.dy) {
          // ball is hitting the face of the paddle
          ball.position =
              Offset(ball.position.dx, ball.position.dy - intersection.height);
          double paddlePct =
              (ball.position.dx + ball.size.width / 2 - paddle.position.dx) /
                  paddle.size.width;
          double maxAngle = pi * .8;
          ball.direction =
              Offset.fromDirection(-maxAngle + maxAngle * paddlePct);
        } else if (ball.position.dx < paddle.position.dx) {
          ball.position =
              Offset(paddle.position.dx - ball.size.width, ball.position.dy);
          ball.direction =
              Offset(-ball.direction.dx.abs(), ball.direction.dy.abs());
        } else if (ballRect.right > paddleRect.right) {
          ball.position = Offset(paddle.position.dx, ball.position.dy);
          ball.direction =
              Offset(-ball.direction.dx.abs(), ball.direction.dy.abs());
        } else {
          ball.position = Offset(ball.position.dx, paddleRect.bottom);
          ball.direction = Offset(0, ball.direction.dy.abs());
        }
      }

      for (Brick brick in bricks) {
        Rect brickRect = brick.rect;
        if (brickRect.overlaps(ballRect)) {
          score += 500;
          destroyedBricks.add(brick);
          Rect intersection = brickRect.intersect(ballRect);
          if (intersection.height > intersection.width) {
            ball.position = Offset(
                ball.position.dx - intersection.width * ball.direction.dx.sign,
                ball.position.dy);
            ball.direction = Offset(-ball.direction.dx, ball.direction.dy);
          } else {
            ball.position = Offset(
                ball.position.dx,
                ball.position.dy -
                    intersection.height * ball.direction.dy.sign);
            ball.direction = Offset(ball.direction.dx, -ball.direction.dy);
          }
          break;
        }
      }
    }

    if (destroyedBricks.isNotEmpty || consumedPowerups.isNotEmpty) {
      setState(() {
        for (Brick destroyedBrick in destroyedBricks) {
          bricks.remove(destroyedBrick);
        }
        for (PowerUp powerup in consumedPowerups) {
          powerups.remove(powerup);
        }
      });
    }

    prevTimeMS = currTimeMS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Column(
              children: [
                Text(
                  "HIGH SCORE",
                  style: TextStyle(color: Colors.red),
                ),
                Text(
                  "$score",
                  style: TextStyle(color: Colors.white),
                ),
                Container(
                  decoration: HexDecoration(
                      primaryColor: Color.fromARGB(255, 90, 125, 143),
                      sideLength: 20.0),
                  child: AspectRatio(
                    aspectRatio: worldSize.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        Size unitSize = Size(
                            constraints.maxWidth / worldSize.width,
                            constraints.maxHeight / worldSize.height);
                        List<Widget> gameObjects = [];
                        gameObjects.add(paddle.render(controller, unitSize));
                        gameObjects.addAll(
                            balls.map((b) => b.render(controller, unitSize)));
                        gameObjects
                            .addAll(bricks.map((b) => b.drawShadow(unitSize)));
                        gameObjects.addAll(
                            bricks.map((b) => b.render(controller, unitSize)));
                        gameObjects.addAll(powerups
                            .map((b) => b.render(controller, unitSize)));
                        return Stack(
                          children: gameObjects,
                        );
                      },
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: Btn(
                            child: Icon(Icons.arrow_left, size: 60),
                            down: () => paddle.left = true,
                            up: () => paddle.left = false)),
                    Expanded(
                        child: Btn(
                            child: Icon(Icons.arrow_right, size: 60),
                            down: () => paddle.right = true,
                            up: () => paddle.right = false))
                  ],
                )
              ],
            ),
          ),
        ));
  }
}

class Btn extends StatelessWidget {
  final void Function() down;
  final void Function() up;
  final Widget child;

  const Btn({Key key, this.down, this.up, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Center(child: child),
        ),
        onTapDown: (details) => down(),
        onTapCancel: up,
        onTapUp: (details) => up());
  }
}

class HexDecoration extends Decoration {
  final Color primaryColor;
  final double sideLength;

  HexDecoration({this.primaryColor, this.sideLength});

  @override
  BoxPainter createBoxPainter([void Function() onChanged]) {
    return HexPainter(primaryColor, sideLength);
  }
}

class HexPainter extends BoxPainter {
  final Color primaryColor;
  final double sideLength;

  HexPainter(this.primaryColor, this.sideLength);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    Rect mainDrawingArea = Rect.fromLTWH(offset.dx, offset.dy,
        configuration.size.width, configuration.size.height);

    double halfHeight = (sideLength / 2.0) / tan(.523599);
    double height = halfHeight * 2.0;

    Offset p1 = Offset(0, 0);
    Offset p2 = Offset(sideLength, 0);
    Offset p3 = Offset(sideLength + halfHeight / 2, halfHeight);
    Offset p4 = Offset(sideLength, height);
    Offset p5 = Offset(0, height);
    Offset p6 = Offset(-halfHeight / 2, halfHeight);
    Offset mp1 = Offset(sideLength / 2, height / 3);
    Offset mp2 = Offset(sideLength / 2, height / 3 * 2);

    Map<List<Offset>, Paint> tris = {
      [p1, p2, mp1]: Paint()
        ..color = Color.lerp(primaryColor, Colors.black, .02)
        ..style = PaintingStyle.fill,
      [p2, p3, mp1]: Paint()
        ..color = Color.lerp(primaryColor, Colors.black, .01)
        ..style = PaintingStyle.fill,
      [p6, p1, mp1]: Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
      [p6, mp1, mp2]: Paint()
        ..color = Color.lerp(primaryColor, Colors.white, .03)
        ..style = PaintingStyle.fill,
      [mp1, mp2, p3]: Paint()
        ..color = Color.lerp(primaryColor, Colors.white, .06)
        ..style = PaintingStyle.fill,
      [p3, p4, mp2]: Paint()
        ..color = Color.lerp(primaryColor, Colors.white, .09)
        ..style = PaintingStyle.fill,
      [p4, p5, mp2]: Paint()
        ..color = Color.lerp(primaryColor, Colors.white, .12)
        ..style = PaintingStyle.fill,
      [p5, p6, mp2]: Paint()
        ..color = Color.lerp(primaryColor, Colors.white, .15)
        ..style = PaintingStyle.fill,
    };

    canvas.save();
    canvas.clipRect(mainDrawingArea);

    int row = 0;
    for (double y = -sideLength;
        y < configuration.size.height + height * 2;
        y += halfHeight) {
      for (double x = row % 2 == 0 ? sideLength + halfHeight / 2.0 : 0;
          x < configuration.size.width + sideLength;
          x += height + sideLength) {
        tris.forEach((t, value) {
          canvas.drawPath(
              Path()
                ..moveTo(t[0].dx + x, t[0].dy + y)
                ..lineTo(t[1].dx + x, t[1].dy + y)
                ..lineTo(t[2].dx + x, t[2].dy + y),
              value);
        });
      }
      row++;
    }
    canvas.restore();
  }
}
