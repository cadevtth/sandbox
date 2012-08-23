require 'open-uri'

class UsersController < ApplicationController
  helper_method :client_id
  
  before_filter :authorize, :only => [:show, :edit, :update, :destroy]
  
  def authorize
    if params[:id].to_i != session[:user_id]
      logger.debug "params[:id]: #{params[:id]}"
      logger.debug "session[:user_id]: #{session[:user_id]}"
      redirect_to root_url, :notice => "Not authorized for that."
    end
  end
  
  def pull_friends
    @user = User.find(session[:user_id])
    
    @user.friends.destroy_all
    
    if @user.facebook_access_token?
      access_token = @user.facebook_access_token
    
      @response = open("https://graph.facebook.com/me/friends?access_token=#{access_token}&fields=name,location").read
    
      @friends = JSON.parse(@response)["data"]
      
      @friends.each do |friend|
        if friend["location"].present? && friend["location"]["name"].present?
          Friend.create :name => friend["name"], :facebook_id => friend["id"], :user_id => @user.id, :location => friend["location"]["name"]
        end
      end
      
    end
    
    redirect_to @user
  end
  
  
  
  def client_id
    return ""
  end
  
  def client_secret
    # DO NOT EXPOSE YOUR APP SECRET IN A PUBLIC GITHUB REPO
    return ""
  end
  
  def auth
    # Exchange code for access token
    code = params[:code]
    
    uri = "https://graph.facebook.com/oauth/access_token?client_id=#{client_id}&redirect_uri=http://localhost:3000/auth&client_secret=#{client_secret}&code=#{code}"
    
    auth_response = open(uri).read
    access_token = auth_response.split('&').first.split('=').last
    
    user = User.find_by_id(session[:user_id])
    user.facebook_access_token = access_token
    
    @my_data = open("https://graph.facebook.com/me?access_token=#{access_token}").read
    
    @my_data = JSON.parse(@my_data)
    
    user.name = @my_data["name"]
    user.facebook_id = @my_data["id"]
    if @my_data["location"]["name"]
      user.location = @my_data["location"]["name"]
    end
    
    user.save
    
    redirect_to user
  end
  
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    @friends = @user.friends
    @json = @user.friends.to_gmaps4rails

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        session[:user_id] = @user.id
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
