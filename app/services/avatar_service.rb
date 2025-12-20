# frozen_string_literal: true

# Service for generating user avatars
# Utility service - returns direct values (no Result types needed)
class AvatarService < ApplicationService
  def initialize(user)
    @user = user
  end

  def url
    if @user.avatar.attached?
      @user.avatar
    else
      generate_initials_avatar
    end
  end

  def initials = "#{@user.first_name&.first}#{@user.last_name&.first}".upcase

  private

  def generate_initials_avatar
    initials = self.initials
    color = Digest::MD5.hexdigest(initials)[0..5]
    svg = <<~SVG
      <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
        <rect width="200" height="200" fill="##{color}"/>
        <text x="50%" y="50%" font-family="Arial" font-size="80" fill="white" text-anchor="middle" dominant-baseline="middle">#{initials}</text>
      </svg>
    SVG
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end
end
