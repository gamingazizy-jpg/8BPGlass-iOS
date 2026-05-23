#pragma once

namespace BallEnums {
    enum State : int {
        DEFAULT = 0,
        IN_POCKET = 1,
        UNKNOWN = 2,
        ERR_STATE = 3
    };

    enum Classification : int {
        NONE = 0,
        SOLID = 1,
        STRIPED = 2,
        EIGHT_BALL = 3,
        CUE_BALL = 4,
        NINE_BALL_RULE = 5,
        ANY = 6,
        ERR_CLASSIFICATION = 7
    };
}
