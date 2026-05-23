#import "PredictionEngine.h"

bool PredictionEngine::pocketStatus[TABLE_POCKETS_COUNT] = {};
float PredictionEngine::shotResult[MAX_SHOT_RESULT_SIZE] = {};

const std::array<Vector2D, TABLE_POCKETS_COUNT>& PredictionEngine::getPockets() {
    static const std::array<Vector2D, TABLE_POCKETS_COUNT> pockets = {{
        Vector2D(-130.8, -67.3),
        Vector2D(0, -72),
        Vector2D(130.8, -67.3),
        Vector2D(130.8, 67.3),
        Vector2D(0, 72),
        Vector2D(-130.8, 67.3)
    }};
    return pockets;
}

const std::array<Vector2D, TABLE_SHAPE_SIZE>& PredictionEngine::getTableShape() {
    static const std::array<Vector2D, TABLE_SHAPE_SIZE> shape = {{
        Vector2D(-127, 53.5), Vector2D(-136.9, 64.1), Vector2D(-138.2, 69.2),
        Vector2D(-136.7, 73.2), Vector2D(-132.7, 74.7), Vector2D(-127.6, 73.4),
        Vector2D(-117, 63.5), Vector2D(-7.8, 63.5), Vector2D(-6.1, 68.6),
        Vector2D(-5.7, 72.7), Vector2D(-3.7, 75.4), Vector2D(0, 76.7),
        Vector2D(3.7, 75.4), Vector2D(5.7, 72.7), Vector2D(6.1, 68.6),
        Vector2D(7.8, 63.5), Vector2D(117, 63.5), Vector2D(127.6, 73.4),
        Vector2D(132.7, 74.7), Vector2D(136.7, 73.2), Vector2D(138.2, 69.2),
        Vector2D(136.9, 64.1), Vector2D(127, 53.5), Vector2D(127, -53.5),
        Vector2D(136.9, -64.1), Vector2D(138.2, -69.2), Vector2D(136.7, -73.2),
        Vector2D(132.7, -74.7), Vector2D(127.6, -73.4), Vector2D(117, -63.5),
        Vector2D(7.8, -63.5), Vector2D(6.1, -68.6), Vector2D(5.7, -72.7),
        Vector2D(3.7, -75.4), Vector2D(0, -76.7), Vector2D(-3.7, -75.4),
        Vector2D(-5.7, -72.7), Vector2D(-6.1, -68.6), Vector2D(-7.8, -63.5),
        Vector2D(-117, -63.5), Vector2D(-127.6, -73.4), Vector2D(-132.7, -74.7),
        Vector2D(-136.7, -73.2), Vector2D(-138.2, -69.2), Vector2D(-136.9, -64.1),
        Vector2D(-127, -53.5)
    }};
    return shape;
}

bool PredictionEngine::determineShotResult(double shotAngle, double shotPower, const Vector2D& shotSpin) {
    if (shotAngle == m_prevAngle && shotPower == m_prevPower && shotSpin.x == m_prevSpin.x && shotSpin.y == m_prevSpin.y)
        return false;

    m_prevAngle = shotAngle;
    m_prevPower = shotPower;
    m_prevSpin = shotSpin;
    m_fastCalc = false;

    initBalls();
    initCueBall(shotAngle, shotPower, shotSpin);
    guiData.collision.firstHitBall = nullptr;

    for (bool& p : pocketStatus) p = false;

    determineBallsPositions();

    for (int i = 0; i < guiData.ballsCount; i++) {
        Ball& ball = guiData.balls[i];
        if (ball.trail.empty() || ball.trail.back() != ball.predictedPosition) {
            ball.trail.push_back(ball.predictedPosition);
        }
    }

    return true;
}

void PredictionEngine::initBalls() {
    guiData.ballsCount = MAX_BALLS_COUNT;
    for (int i = 0; i < guiData.ballsCount; i++) {
        Ball& ball = guiData.balls[i];
        ball.index = i;
        ball.state = BallEnums::State::DEFAULT;
        ball.onTable = true;
        ball.classification = BallEnums::Classification::NONE;
        ball.position = Vector2D(0, 0);
        ball.predictedPosition = ball.position;
        ball.velocity = Vector2D(0, 0);
        ball.pocketIndex = -1;
        ball.trail.clear();
        ball.trail.reserve(20);
        ball.trail.push_back(ball.position);
    }
}

void PredictionEngine::initCueBall(double shotAngle, double shotPower, const Vector2D& shotSpin) {
    double angleCos = round(cos(shotAngle) * 10000.0) / 10000.0;
    double angleSin = round(sin(shotAngle) * 10000.0) / 10000.0;
    Ball& cueBall = guiData.balls[0];
    cueBall.velocity.x = shotPower * angleCos;
    cueBall.velocity.y = shotPower * angleSin;
}

void PredictionEngine::determineBallsPositions() {
    bool anyMoving;
    double time, time2;

    do {
        time = TIME_PER_TICK;
        do {
            time2 = time;
            guiData.collision.valid = false;

            for (int i = 0; i < guiData.ballsCount; i++) {
                Ball& ball = guiData.balls[i];
                if (ball.onTable) {
                    findNextCollision(ball, &time2);
                }
            }

            for (int i = 0; i < guiData.ballsCount; i++) {
                Ball& ball = guiData.balls[i];
                if (ball.onTable && isMovingOrSpinning(ball)) {
                    moveBall(ball, time2);
                }
            }

            if (guiData.collision.valid) {
                handleCollision();
            }

            time -= time2;
        } while (time > MIN_TIME);

        anyMoving = false;
        for (int i = 0; i < guiData.ballsCount; i++) {
            Ball& ball = guiData.balls[i];
            if (ball.onTable) {
                calcVelocity(ball);
                if (isMovingOrSpinning(ball)) {
                    anyMoving = true;
                }
            }
        }
    } while (anyMoving);
}

void PredictionEngine::findNextCollision(Ball& ball, double* time) {
    auto pockets = getPockets();

    if (ball.state == BallEnums::State::DEFAULT) {
        for (int i = ball.index + 1; i < guiData.ballsCount; i++) {
            Ball& other = guiData.balls[i];
            if (other.state == BallEnums::State::DEFAULT && isBallBallCollision(ball, other, time)) {
                guiData.collision.valid = true;
                guiData.collision.ballA = &ball;
                guiData.collision.type = Collision::Type::BALL;
                guiData.collision.ballB = &other;
            }
        }
    }

    if (willCollideWithTable(ball, time)) {
        if (ball.state == BallEnums::State::IN_POCKET) {
            ball.velocity.x -= ball.predictedPosition.x * *time * 1.5;
            ball.velocity.y -= ball.predictedPosition.y * *time * 1.5;
        } else if (ball.state == BallEnums::State::DEFAULT) {
            for (int i = 0; i < TABLE_POCKETS_COUNT; i++) {
                Vector2D delta = pockets[i] - ball.predictedPosition;
                double distSq = delta.dot(delta);
                if (distSq < POCKET_RADIUS_SQUARE) {
                    double unk = *time * 120.0;
                    ball.velocity.x += delta.x * unk;
                    ball.velocity.y += delta.y * unk;
                    if (distSq < BALL_RADIUS_SQUARE) {
                        ball.state = BallEnums::State::IN_POCKET;
                        ball.pocketIndex = i;
                        pocketStatus[i] = true;
                    }
                }
            }
        }
        determineBallTableCollision(ball, time);
    }

    if (ball.state == BallEnums::State::IN_POCKET) {
        ball.state = BallEnums::State::UNKNOWN;
        ball.onTable = false;
        ball.velocity = Vector2D(0, 0);
    }
}

bool PredictionEngine::isBallBallCollision(Ball& a, Ball& b, double* smallestTime) {
    Vector2D delta = b.predictedPosition - a.predictedPosition;
    Vector2D velDelta = b.velocity - a.velocity;
    double a2 = velDelta.dot(velDelta);
    if (a2 == 0.0) return false;
    double a1 = 2.0 * delta.dot(velDelta);
    double a0 = delta.dot(delta) - 4.0 * BALL_RADIUS_SQUARE;
    double disc = a1 * a1 - 4.0 * a2 * a0;
    if (disc < 0.0) return false;
    double t = (-a1 - sqrt(disc)) / (2.0 * a2);
    if (t <= 0.0 || t - 1E-11 > *smallestTime) return false;
    *smallestTime = t;
    return true;
}

bool PredictionEngine::willCollideWithTable(Ball& ball, const double* smallestTime) {
    double cx = ball.predictedPosition.x;
    double cy = ball.predictedPosition.y;
    double px = cx + ball.velocity.x * *smallestTime;
    double py = cy + ball.velocity.y * *smallestTime;

    double leftX, rightX, topY, bottomY;
    if (ball.velocity.x > 0.0) { leftX = cx; rightX = px; }
    else { leftX = px; rightX = cx; }
    if (ball.velocity.y > 0.0) { topY = cy; bottomY = py; }
    else { topY = py; bottomY = cy; }

    double halfW = TABLE_HALF_WIDTH - BALL_RADIUS;
    double halfH = TABLE_HALF_HEIGHT - BALL_RADIUS;
    return (leftX < -halfW || rightX > halfW || topY < -halfH || bottomY > halfH);
}

void PredictionEngine::determineBallTableCollision(Ball& ball, double* smallestTime) {
    auto shape = getTableShape();
    for (int i = 0; i < TABLE_SHAPE_SIZE; i++) {
        const Vector2D& p1 = shape[i];
        const Vector2D& p2 = shape[(i + 1) % TABLE_SHAPE_SIZE];
        if (isBallLineCollision(ball, smallestTime, p1, p2)) {
            double angle = NumberUtils::calcAngle(p2.x - p1.x, p2.y - p1.y);
            guiData.collision.valid = true;
            guiData.collision.ballA = &ball;
            guiData.collision.type = Collision::Type::LINE;
            guiData.collision.angle = -angle;
        } else if (isBallPointCollision(ball, smallestTime, p1)) {
            guiData.collision.valid = true;
            guiData.collision.ballA = &ball;
            guiData.collision.point = p1;
            guiData.collision.type = Collision::Type::POINT;
        }
    }
}

bool PredictionEngine::isBallLineCollision(Ball& ball, double* pTime, const Vector2D& a, const Vector2D& b) {
    if (ball.velocity.x == 0.0 && ball.velocity.y == 0.0) return false;

    Vector2D delta = b - a;
    double cross = delta.y * ball.velocity.x - delta.x * ball.velocity.y;
    if (cross == 0.0) return false;

    double inv = 1.0 / sqrt(delta.dot(delta));
    double r = BALL_RADIUS * inv;
    double dx = ball.predictedPosition.x - a.x - delta.y * r;
    double dy = ball.predictedPosition.y - a.y + delta.x * r;
    double t1 = (dx * -ball.velocity.y - dy * -ball.velocity.x) / cross;
    if (t1 <= 0.0 || t1 >= 1.0) return false;

    double t = (delta.x * dy - delta.y * dx) / cross;
    if (t <= 0.0 || t - 1E-11 > *pTime) return false;

    double nx = delta.y * inv;
    double ny = -delta.x * inv;
    if (ball.velocity.x * nx + ball.velocity.y * ny > 0.0) return false;

    *pTime = t;
    return true;
}

bool PredictionEngine::isBallPointCollision(Ball& ball, double* smallestTime, const Vector2D& point) {
    Vector2D delta = point - ball.predictedPosition;
    double v16 = -2.0 * (ball.velocity.x * delta.x + ball.velocity.y * delta.y);
    if (v16 >= 0.0) return false;

    double velSq = ball.velocity.dot(ball.velocity);
    double distSq = delta.dot(delta);
    double unkSq = v16 * v16;

    if (distSq - unkSq / (4.0 * velSq) >= BALL_RADIUS_SQUARE) return false;

    double t = (-v16 - sqrt(unkSq - 4.0 * velSq * (distSq - BALL_RADIUS_SQUARE))) / (2.0 * velSq);
    if (t < 0.0 || t > *smallestTime) return false;

    *smallestTime = t;
    return true;
}

void PredictionEngine::handleCollision() {
    Ball& ballA = *guiData.collision.ballA;
    Ball& ballB = *guiData.collision.ballB;

    switch (guiData.collision.type) {
        case Collision::Type::BALL:
            handleBallBallCollision();
            if (guiData.collision.firstHitBall == nullptr)
                guiData.collision.firstHitBall = &ballB;
            break;
        case Collision::Type::LINE:
            calcVelocityPostCollision(ballA, guiData.collision.angle);
            break;
        default:
        {
            Vector2D delta = {
                guiData.collision.point.y - ballA.predictedPosition.y,
                -(guiData.collision.point.x - ballA.predictedPosition.x)
            };
            guiData.collision.angle = -NumberUtils::calcAngle(delta.x, delta.y);
            calcVelocityPostCollision(ballA, guiData.collision.angle);
            break;
        }
    }
}

void PredictionEngine::handleBallBallCollision() {
    Ball& a = *guiData.collision.ballA;
    Ball& b = *guiData.collision.ballB;

    Vector2D relPos = a.predictedPosition - b.predictedPosition;
    double invDist = 1.0 / sqrt(relPos.dot(relPos));
    Vector2D norm = relPos * invDist;

    double va = a.velocity.dot(norm);
    double vb = b.velocity.dot(norm);
    Vector2D vaVec = norm * va;
    Vector2D vbVec = norm * vb;

    a.velocity.x = vbVec.x - (vaVec.x - a.velocity.x);
    a.velocity.y = vbVec.y - (vaVec.y - a.velocity.y);
    b.velocity.x = vaVec.x - (vbVec.x - b.velocity.x);
    b.velocity.y = vaVec.y - (vbVec.y - b.velocity.y);
}

void PredictionEngine::calcVelocity(Ball& ball) {
    if (!isMovingOrSpinning(ball)) return;

    double spd = sqrt(ball.velocity.dot(ball.velocity));
    double friction = spd * 0.0014577;
    if (friction > TIME_PER_TICK) {
        double dt = (friction < TIME_PER_TICK) ? friction : TIME_PER_TICK;
        double reduction = 196.0 * dt / spd;
        ball.velocity.x -= ball.velocity.x * reduction / spd * dt * 196.0;
        ball.velocity.y -= ball.velocity.y * reduction / spd * dt * 196.0;
    }

    if (spd > 0.0 && spd < TIME_PER_TICK) {
        double factor = 1.0 - (TIME_PER_TICK - spd) * 10.878 / spd;
        if (factor < 0.0) factor = 0.0;
        ball.velocity = ball.velocity * factor;
    }
}

void PredictionEngine::calcVelocityPostCollision(Ball& ball, const double& angle) {
    double angleCos = round(cos(angle) * 10000.0) / 10000.0;
    double angleSin = round(sin(angle) * 10000.0) / 10000.0;

    double vx = angleCos * ball.velocity.x - angleSin * ball.velocity.y;
    double vy = angleSin * ball.velocity.x + angleCos * ball.velocity.y;
    double newVy = -0.804 * vy;

    ball.velocity.x = angleSin * newVy + angleCos * vx;
    ball.velocity.y = angleCos * newVy - vx * angleSin;
}

void PredictionEngine::moveBall(Ball& ball, const double& time) {
    if (ball.velocity.x != 0.0 || ball.velocity.y != 0.0) {
        ball.predictedPosition.x += ball.velocity.x * time;
        ball.predictedPosition.y += ball.velocity.y * time;

        if (!m_fastCalc) {
            size_t last = ball.trail.size() - 1;
            if (last > 1) {
                Vector2D& a = ball.trail[last - 1];
                Vector2D& b = ball.trail[last];
                Vector2D& c = ball.predictedPosition;
                if (((b.y - a.y) * (c.x - b.x)) == ((c.y - b.y) * (b.x - a.x)))
                    return;
            }
            ball.trail.push_back(ball.predictedPosition);
        }
    }
}

bool PredictionEngine::isMovingOrSpinning(const Ball& ball) {
    return ball.velocity.x != 0.0 || ball.velocity.y != 0.0;
}
