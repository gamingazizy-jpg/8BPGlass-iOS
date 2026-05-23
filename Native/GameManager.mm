#import "GameManager.h"

GameManager& GameManager::shared() {
    static GameManager instance;
    return instance;
}

GameManager::GameManager()
    : m_ball(Vector2D(100, 200))
    , m_tableWidth(1000)
    , m_tableHeight(500)
{
}

void GameManager::update(float deltaTime) {
    m_ball.update(deltaTime);
}

void GameManager::reset() {
    m_ball.setPosition(Vector2D(100, 200));
    m_ball.setVelocity(Vector2D(0, 0));
    m_prediction.clearPath();
}

void GameManager::setTableBounds(float width, float height) {
    m_tableWidth = width;
    m_tableHeight = height;
}
