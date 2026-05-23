#pragma once

inline constexpr int MAX_BALLS_COUNT = 16;
inline constexpr double BALL_RADIUS = 3.800475;
inline constexpr double BALL_RADIUS_SQUARE = BALL_RADIUS * BALL_RADIUS;

inline constexpr double TABLE_WIDTH = 254.0;
inline constexpr double TABLE_HEIGHT = 127.0;
inline constexpr double TABLE_HALF_WIDTH = TABLE_WIDTH / 2.0;
inline constexpr double TABLE_HALF_HEIGHT = TABLE_HEIGHT / 2.0;

inline constexpr int TABLE_POCKETS_COUNT = 6;
inline constexpr int TABLE_SHAPE_SIZE = 46;
inline constexpr double POCKET_RADIUS = 8.0;
inline constexpr double POCKET_RADIUS_SQUARE = POCKET_RADIUS * POCKET_RADIUS;

inline constexpr int MAX_SHOT_RESULT_SIZE = 50000;
inline constexpr double TIME_PER_TICK = 0.005;
inline constexpr double MIN_TIME = 1E-11;

inline constexpr double PI = 3.14159265358979;
inline constexpr double PI_0_5 = PI / 2.0;
inline constexpr double PI_1_5 = PI * 1.5;

struct Candidate {
    int idx;
    double angle;
    double score;
    int pocketIndex;
    double power;
    bool operator<(const Candidate& other) const { return score < other.score; }
};
