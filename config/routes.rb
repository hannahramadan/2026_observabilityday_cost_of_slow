Rails.application.routes.draw do
  scope "/v1" do
    post "ask", to: "asks#create"
    post "asks/:id/abandon", to: "abandons#create"
    post "tickets", to: "tickets#create"
  end
  post "/admin/slow", to: "admin#slow"
end
