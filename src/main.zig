const rl = @import("raylib");
const std = @import("std");

const screenWidth = 1800;
const screenHeight = 1000;

const paddleOffset = 40;
const paddleWidth = 30;
const paddleHeight = 150;
const paddleMoveDistance = 20;

var leftPaddle: rl.Rectangle = .{.x = paddleOffset, .y = paddleOffset, .width = paddleWidth, .height = paddleHeight};
var rightPaddle: rl.Rectangle = .{
    .x = screenWidth - paddleOffset - paddleWidth,
    .y = screenHeight - paddleOffset - paddleHeight,
    .width = paddleWidth,
    .height = paddleHeight
};

var leftPaddleMoveDir : f32 = 1.0;
var rightPaddleMoveDir : f32 = 1.0;

const ballSize = 30;
var ball : rl.Rectangle = .{.x = screenWidth / 2, .y = screenHeight / 2, .width = ballSize, .height = ballSize};

var ballXVelo : f32 = 17.0;
var ballYVelo : f32 = 1.0;

var ballInPlay = false;

var leftPlayerScore : u32 = 0;
var rightPlayerScore : u32 = 0;

var rand : f32 = 0.0;

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "Pong");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60);

    try resetBallInBackground();

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        updatePaddles();

        if (ballInPlay) {
            ball.x += ballXVelo;

            // ball hits left or right paddle
            if (AABB(ball, leftPaddle)) {
                ball.x = leftPaddle.x + leftPaddle.width + 1;
                ballXVelo *= -1;
                ballYVelo = leftPaddleMoveDir * lazyRand(4.0, 10.0);
            }
            else if (AABB(ball, rightPaddle)) {
                ball.x = rightPaddle.x - 1 - ball.width;
                ballXVelo *= -1;
                ballYVelo = rightPaddleMoveDir * lazyRand(4.0, 10.0);
            }

            ball.y += ballYVelo;

            if (ball.y < 0 or ball.y + ball.height > screenHeight) { // bounce off floor or ceiling
                ballYVelo *= -1.0;
            }
        }

        if (ball.x + ball.width > screenWidth or ball.x < 0) { // score and reset ball
            if (ball.x + ball.width > screenWidth) {
                leftPlayerScore += 1;
            }
            else {
                rightPlayerScore += 1;
            }

            try resetBallInBackground();
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black);

        rl.drawRectangleLines(0, 0, screenWidth, screenHeight, .blue); // world border
        rl.drawRectangleRec(leftPaddle, .white);
        rl.drawRectangleRec(rightPaddle, .white);
        rl.drawRectangleRec(ball, .white);
        
        var buf: [32]u8 = undefined;
        var str = try std.fmt.bufPrintZ(&buf, "{}", .{leftPlayerScore});
        rl.drawText(str, screenWidth / 2 - 100, screenHeight / 4, 80, .light_gray);

        str = try std.fmt.bufPrintZ(&buf, "{}", .{rightPlayerScore});
        rl.drawText(str, screenWidth / 2 + 100, screenHeight / 4, 80, .light_gray);

        rand += 1.0;
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

fn resetBallInBackground() !void {
    ballInPlay = false;
    var thread = try std.Thread.spawn(.{}, resetBall, .{});
    thread.detach();
}

fn resetBall() void {
    defer ballInPlay = true;

    ball.x = screenWidth / 2;
    ball.y = screenHeight / 2;
    
    // wait for a second before releasing the ball
    var timespec: std.posix.timespec = .{ .sec = 1, .nsec = 0 };
    _ = std.posix.system.nanosleep(&timespec, &timespec);

    ballXVelo *= -1.0;
}

fn lazyRand(min : f32, range : f32) f32 {
    return @mod(rand, range) + min;
}
