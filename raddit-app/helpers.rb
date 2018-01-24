helpers do
  # a helper method to turn a string ID
  # representation into a BSON::ObjectId
  def object_id(val)
    BSON::ObjectId.from_string(val)
  rescue BSON::ObjectId::Invalid
    nil
  end

  def document_by_id(id)
    id = object_id(id) if String === id
    if id.nil?
      {}.to_json
    else
      document = settings.post_db.find(_id: id).to_a.first
      (document || {}).to_json
    end
  end

  def log_event(type, name, message, params = '{}')
    case type
    when 'error'
      logger.error("event=#{name} | " \
                   "message=\'#{message}\' | " \
                   "params: #{params.to_json}")
    when 'info'
      logger.info("event=#{name} | " \
                  "message=\'#{message}\' | " \
                  "params: #{params.to_json}")
    when 'warning'
      logger.warn("event=#{name} | " \
                  "message=\'#{message}\' |  " \
                  "params: #{params.to_json}")
    end
  end

  def flash_danger(message)
    session[:flashes] << { type: 'alert-danger', message: message }
  end

  def flash_success(message)
    session[:flashes] << { type: 'alert-success', message: message }
  end
end
