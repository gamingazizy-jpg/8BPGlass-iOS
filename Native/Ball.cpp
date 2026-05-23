#include "Ball.h"

Ball::Ball()
    : m_position(0, 0)
    , m_velocity(0, 0)
    , m_radius(8.0f)
    , m_mass(1.0f)
{
}

Ball::Ball(const Vector2D& position)
    : m_position(position)
    , m_velocity(0, 0)
    , m_radius(8.0f)
    , m_mass(1.0f)
{
}

void Ball::update(float deltaTime) {
    m_position = m_position + m_velocity * deltaTime;
    m_velocity = m_velocity * 0.98f;
}

void Ball::applyForce(const Vector2D& force) {
    m_velocity = m_velocity + force * (1.0f / m_mass);
}
