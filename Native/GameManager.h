#pragma once

#include "Ball.h"
#include "Prediction.h"
#include <vector>

class GameManager {
public:
    static GameManager& shared();

    void update(float deltaTime);
    void reset();

    Ball& getBall() { return m_ball; }
    Prediction& getPrediction() { return m_prediction; }

    void setTableBounds(float width, float height);
    float getTableWidth() const { return m_tableWidth; }
    float getTableHeight() const { return m_tableHeight; }

private:
    GameManager();
    ~GameManager() = default;
    GameManager(const GameManager&) = delete;
    GameManager& operator=(const GameManager&) = delete;

    Ball m_ball;
    Prediction m_prediction;
    float m_tableWidth;
    float m_tableHeight;
};
