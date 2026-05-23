#pragma once

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

namespace NumberUtils {
    inline double normalizeDoublePrecision(double value, double negativeThreshold = 0.0, double negativeExtraLen = 0.0, size_t maxLen = 7) {
        if (std::abs(value) >= 10000.0) return std::floor(value);
        char buffer[256];
        std::snprintf(buffer, sizeof(buffer), "%lf", value);
        size_t strLen = std::strlen(buffer);
        size_t allowedLen = maxLen;
        if (value < negativeThreshold) allowedLen = maxLen + negativeExtraLen;
        if (strLen > allowedLen) buffer[allowedLen] = '\0';
        double result = 0.0;
        std::sscanf(buffer, "%lf", &result);
        return result;
    }

    inline double calcAngle(double x, double y) {
        double angle;
        if (x == 0.0) {
            angle = PI_1_5;
            if (y >= 0.0) angle = PI_0_5;
        } else {
            angle = atan(y / x);
            angle = round(angle * 10000.0) / 10000.0;
            if (x < 0.0) angle += PI;
        }
        return angle;
    }

    inline double calcAngle(double dx, double dy, double sx, double sy) {
        return calcAngle(dx - sx, dy - sy);
    }
}
