#import "Prediction.h"

Prediction::Prediction()
    : m_confidence(0.0f)
{
}

bool Prediction::determineShotResult(bool isAuto) {
    // Demo: predict using a sample shot
    bool result = m_engine.determineShotResult(0.5, 500.0, Vector2D(0, 0));

    // Copy trail points to our path
    m_pathPoints.clear();
    for (int i = 0; i < m_engine.guiData.ballsCount; i++) {
        auto& ball = m_engine.guiData.balls[i];
        for (auto& pt : ball.trail) {
            m_pathPoints.push_back(pt);
        }
    }

    m_confidence = result ? 0.85f : 0.0f;
    return result;
}

void Prediction::addPathPoint(const Vector2D& point) {
    m_pathPoints.push_back(point);
    m_confidence = 0.5f;
}

void Prediction::clearPath() {
    m_pathPoints.clear();
    m_confidence = 0.0f;
}
