Rack::Attack.throttle("api/v1/auth", limit: 5, period: 60) do |req|
  req.ip if req.path.start_with?("/api/v1/auth") && req.post?
end

Rack::Attack.throttle("api/v1/auth/sign_up", limit: 3, period: 60) do |req|
  req.ip if req.path == "/api/v1/auth/sign_up" && req.post?
end
