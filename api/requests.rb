class RequestRepo < ROM::Repository[:requests]
  commands :create

  def for_visitor(visitor_id)
    requests.where(visitor_id: visitor_id).to_a
  end
end
