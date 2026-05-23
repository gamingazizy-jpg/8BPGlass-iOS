#pragma once

#include "Vector/Vector2D.h"

class Ball {
public:
    Ball();
    explicit Ball(const Vector2D& position);

    void update(float deltaTime);
    void applyForce(const Vector2D& force);

    Vector2D getPosition() const { return m_position; }
    Vector2D getVelocity() const { return m_velocity; }
    float getRadius() const { return m_radius; }

    void setPosition(const Vector2D& pos) { m_position = pos; }
    void setVelocity(const Vector2D& vel) { m_velocity = vel; }

private:
    Vector2D m_position;
    Vector2D m_velocity;
    float m_radius;
    float m_mass;
};
