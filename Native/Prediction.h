#pragma once

#include <vector>
#include "Vector/Vector2D.h"
#include "PredictionEngine.h"

class Prediction {
public:
    Prediction();

    bool determineShotResult(bool isAuto);
    void addPathPoint(const Vector2D& point);
    void clearPath();

    const std::vector<Vector2D>& getPathPoints() const { return m_pathPoints; }
    float getConfidence() const { return m_confidence; }

    PredictionEngine* getEngine() { return &m_engine; }

private:
    PredictionEngine m_engine;
    std::vector<Vector2D> m_pathPoints;
    float m_confidence;
};
