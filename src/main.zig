const rl = @import("raylib");
const std = @import("std");

const screenWidth = 1800;
const screenHeight = 1000;

const paddleOffset = 40;
const paddleWidth = 30;
const paddleHeight = 150;
const paddleMoveDistance = 15;

var leftPaddle: rl.Rectangle = .{.x = paddleOffset, .y = paddleOffset, .width = paddleWidth, .height = paddleHeight};
var rightPaddle: rl.Rectangle = .{
    .x = screenWidth - paddleOffset - paddleWidth,
    .y = screenHeight - paddleOffset - paddleHeight,
    .width = paddleWidth,
    .height = paddleHeight
};

var leftPaddleMoveDir : f32 = 1.0;
var rightPaddleMoveDir : f32 = 1.0;

var ball : rl.Rectangle = .{.x = screenWidth / 2, .y = screenHeight / 2, .width = ballSize, .height = ballSize};
const ballSize = 30;

var ballXVelo : f32 = 17.0;
var ballYVelo : f32 = 1.0;

var ballInPlay = true;

var leftPlayerScore : u32 = 0;
var rightPlayerScore : u32 = 0;

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "Pong");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        rl.drawRectangleLines(0, 0, screenWidth, screenHeight, .blue);

        updatePaddles();

        if (ballInPlay) {
            ball.x += ballXVelo;

            if (AABB(ball, leftPaddle)) {
                ballXVelo *= -1;
                ballYVelo = leftPaddleMoveDir * 4.0;
            }
            else if (AABB(ball, rightPaddle)) {
                ballXVelo *= -1;
                ballYVelo = rightPaddleMoveDir * 4.0;
            }

            ball.y += ballYVelo;

            if (ball.y < 0 or ball.y + ball.height > screenHeight) {
                ballYVelo *= -1.0;
            }
        }

        if (ball.x + ballSize > screenWidth or ball.x < 0) {
            if (ball.x + ballSize > screenWidth) {
                leftPlayerScore += 1;
            }
            else {
                rightPlayerScore += 1;
            }

            resetBall();
        }

        rl.drawRectangleRec(leftPaddle, .white);
        rl.drawRectangleRec(rightPaddle, .white);
        rl.drawRectangleRec(ball, .white);
        
        var buf: [32]u8 = undefined;
        var str = try std.fmt.bufPrintZ(&buf, "{}", .{leftPlayerScore});
        rl.drawText(str, screenWidth / 2 - 100, screenHeight / 4, 80, .light_gray);

        str = try std.fmt.bufPrintZ(&buf, "{}", .{rightPlayerScore});
        rl.drawText(str, screenWidth / 2 + 100, screenHeight / 4, 80, .light_gray);
    }
}

fn AABB(a : rl.Rectangle, b : rl.Rectangle) bool { // check if two rectangles collide
    return 
        a.x < b.x + b.width 
        and a.x + a.width > b.x // x overlap
        and a.y < b.y + b.height
        and a.y + a.height > b.y; // y overlap
}

fn updatePaddles() void {
    if (rl.isKeyDown(rl.KeyboardKey.up) and rightPaddle.y > 0) {
        rightPaddle.y -= paddleMoveDistance;
        rightPaddleMoveDir = -1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.down) and rightPaddle.y + paddleHeight < screenHeight) {
        rightPaddle.y += paddleMoveDistance;
        rightPaddleMoveDir = 1.0;
    }

    if (rl.isKeyDown(rl.KeyboardKey.w) and leftPaddle.y > 0) {
        leftPaddle.y -= paddleMoveDistance;
        leftPaddleMoveDir = -1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.s) and leftPaddle.y + paddleHeight < screenHeight) {
        leftPaddle.y += paddleMoveDistance;
        leftPaddleMoveDir = 1.0;
    }
}

fn resetBall() void {
    ballInPlay = false;
    defer ballInPlay = true;

    ball.x = screenWidth / 2;
    ball.y = screenHeight / 2;

    ballXVelo *= -1.0;
}

