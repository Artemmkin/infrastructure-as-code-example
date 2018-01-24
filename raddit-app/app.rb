require 'sinatra'
require 'sinatra/reloader'
require 'json/ext'
require 'haml'
require 'uri'
require 'mongo'
require 'bcrypt'
require_relative 'helpers'

# Database connection params
DATABASE_HOST ||= ENV['DATABASE_HOST'] || '127.0.0.1'
DATABASE_PORT ||= ENV['DATABASE_PORT'] || '27017'
DATABASE_NAME ||= ENV['DATABASE_NAME'] || 'test'
DB_URL ||= "mongodb://#{DATABASE_HOST}:#{DATABASE_PORT}"

# App version
VERSION ||= File.read('VERSION').strip
@@version = VERSION

configure do
  db = Mongo::Client.new(DB_URL, database: DATABASE_NAME,
                                 heartbeat_frequency: 2)
  Mongo::Logger.logger.level = Logger::WARN
  set :post_db, db[:posts]
  set :comment_db, db[:comments]
  set :logging, false
  set :mylogger, Logger.new(STDOUT)
  set :server, :puma
  set :bind, '0.0.0.0'
  enable :sessions
end

before do
  session[:flashes] = [] if session[:flashes].class != Array
  env['rack.logger'] = settings.mylogger # set custom logger
end

# show all posts
get '/' do
  @title = 'Posts'
  begin
    @posts = JSON.parse(settings.post_db.find.sort(timestamp: -1).to_a.to_json)
  rescue StandardError => e
    log_event('error', 'posts_show',
              "Failed to show posts. Reason: #{e.message}")
    flash_danger('Can\'t show blog posts, some problems with the database. ' \
                 '<a href="." class="alert-link">Refresh?</a>')
  end
  @flashes = session[:flashes]
  session[:flashes] = nil
  haml :index
end

# show the form for creating a new post
get '/new' do
  @title = 'New post'
  @flashes = session[:flashes]
  session[:flashes] = nil
  haml :create
end

# create a new post in the DB once the form is sent
post '/new' do
  db = settings.post_db
  if params['link'] =~ URI::DEFAULT_PARSER.regexp[:ABS_URI]
    begin
      result = db.insert_one title: params['title'],
                             created_at: Time.now.to_i,
                             link: params['link'],
                             votes: 0
      db.find(_id: result.inserted_id).to_a.first
    rescue StandardError => e
      log_event('error', 'post_create',
                "Failed to create a post. Reason: #{e.message}", params)
      flash_danger("Can't save your post to the database :(")
    else
      log_event('info', 'post_create', 'Successfully created a post', params)
      flash_success('Post successuly published')
    end
    redirect '/'
  else
    flash_danger('Invalid URL')
    log_event('warning', 'post_create', 'Invalid URL', params)
    redirect back
  end
end

# vote on a post
put '/post/:id/vote/:type' do
  begin
    id = object_id(params[:id])
    post = JSON.parse(document_by_id(params[:id]))
    post['votes'] += params[:type].to_i
    settings.post_db.find(_id: id)
            .find_one_and_update('$set' => { votes: post['votes'] })
    document_by_id(id)
  rescue StandardError => e
    flash_danger('Can\'t save your vote :(')
    log_event('error', 'vote',
              "Failed to vote. Reason: #{e.message}", params)
  end
  redirect back
end

# show some specific post
get '/post/:id' do
  @title = 'Post'
  begin
    @post = JSON.parse(document_by_id(params[:id]))
  rescue StandardError => e
    log_event('error', 'post_show',
              "Counldn't show the post. Reason: #{e.message}", params)
    halt 404, 'Not found'
  end

  begin
    id = object_id(params[:id])
    @comments = JSON.parse(settings.comment_db
                                   .find(post_id: id.to_s).to_a.to_json)
  rescue StandardError => e
    log_event('error', 'comments_show',
              "Counldn't show comments. Reason: #{e.message}", params)
    flash_danger("Can't show comments :(")
  else
    log_event('info', 'post_show',
              'Successfully showed a post', params)
  end
  @flashes = session[:flashes]
  session[:flashes] = nil
  haml :show
end

# post a comment to the post
post '/post/:id/comment' do
  content_type :json
  db = settings.comment_db
  begin
    result = db.insert_one post_id: params[:id],
                           name: session[:username],
                           body: params['body'],
                           created_at: Time.now.to_i
    db.find(_id: result.inserted_id).to_a.first
  rescue StandardError => e
    log_event('error', 'comment_create',
              "Counldn't save the comment. Reason: #{e.message}", params)
    flash_danger("Can\'t save the comment to the database :(")
  else
    log_event('info', 'create_comment',
              'Successfully created a new post', params)
    flash_success('Comment successuly published')
  end
  redirect back
end

# other HTTP paths
get '/*' do
  halt 404, 'Not found'
end
