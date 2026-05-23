#pragma once

#include "GameConstants.h"
#include "NumberUtils.h"
#include "BallEnums.h"
#include "Vector/Vector2D.h"
#include <vector>
#include <array>
#include <cmath>

class PredictionEngine {
public:
    struct Ball {
        int index;
        BallEnums::Classification classification;
        BallEnums::State state;
        bool onTable;
        int pocketIndex;

        Vector2D velocity;
        Vector2D position;
        Vector2D predictedPosition;
        std::vector<Vector2D> trail;

        Ball()
            : index(0), classification(BallEnums::Classification::ERR_CLASSIFICATION),
              state(BallEnums::State::ERR_STATE), onTable(false), pocketIndex(-1),
              velocity(), position(), predictedPosition() {}
    };

    struct Collision {
        enum Type { BALL, LINE, POINT };
        bool valid;
        Type type;
        double angle;
        Vector2D point;
        Ball* ballA;
        Ball* ballB;
        Ball* firstHitBall;

        Collision()
            : valid(false), type(POINT), angle(0.0), point(),
              ballA(nullptr), ballB(nullptr), firstHitBall(nullptr) {}
    };

    struct SceneData {
        int ballsCount;
        Ball balls[MAX_BALLS_COUNT];
        Collision collision;
        bool shotState;

        SceneData() : ballsCount(0), collision(), shotState(false) {}
    } guiData;

    static bool pocketStatus[TABLE_POCKETS_COUNT];
    static float shotResult[MAX_SHOT_RESULT_SIZE];
    int shotResultSize = 0;

    PredictionEngine() = default;

    void initBalls();
    void initCueBall(double shotAngle, double shotPower, const Vector2D& shotSpin);
    void determineBallsPositions();
    void handleCollision();
    void handleBallBallCollision();
    bool determineShotResult(double shotAngle, double shotPower, const Vector2D& shotSpin);

    static const std::array<Vector2D, TABLE_POCKETS_COUNT>& getPockets();
    static const std::array<Vector2D, TABLE_SHAPE_SIZE>& getTableShape();

private:
    double m_prevAngle = 0.0;
    double m_prevPower = 0.0;
    Vector2D m_prevSpin;
    bool m_fastCalc = false;

    void findNextCollision(Ball& ball, double* time);
    bool isBallBallCollision(Ball& a, Ball& b, double* smallestTime);
    bool willCollideWithTable(Ball& ball, const double* smallestTime);
    void determineBallTableCollision(Ball& ball, double* smallestTime);
    bool isBallLineCollision(Ball& ball, double* pTime, const Vector2D& a, const Vector2D& b);
    bool isBallPointCollision(Ball& ball, double* smallestTime, const Vector2D& point);
    void calcVelocity(Ball& ball);
    void calcVelocityPostCollision(Ball& ball, const double& angle);
    void moveBall(Ball& ball, const double& time);
    bool isMovingOrSpinning(const Ball& ball);
};
