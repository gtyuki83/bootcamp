class PostsController < ApplicationController
before_action :authenticate_user!, :except=>[:index, :show]
before_action :ensure_correct_user, {only: [:edit, :update, :destroy]}

  def index
    @posts = Post.all.order(created_at: :desc)
    ids = REDIS.zrevrange "posts/daily/#{Date.today.to_s}", 0, 2
    @hi_posts = Post.where(id: ids)
    # today = Date.today.to_s
    # @daily_pageviews = Hash.new
    #   @posts.each do |post|
    #   @daily_pageviews[post.id] = REDIS.get "posts/daily/#{today}/#{post.id}"
    #   end
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(create_params)
    if @post.save
      redirect_to("/")
    else
      render("/posts/new")
    end
  end


  def show
    @post = Post.find_by(id: params[:id])
    REDIS.zincrby "posts/daily/#{Date.today.to_s}", 1, "#{@post.id}"
  end

  def edit
    @post = Post.find_by(id: params[:id])
  end

  def update
    @post = Post.find_by(id:params[:id])
    if @post.update(params.require(:post).permit(:title, :body))
      redirect_to("/")
    else
      render("/posts/#{post.id}/edit")
    end
  end

  def destroy
    @post = Post.find_by(id:params[:id])
    @post.destroy
    redirect_to("/")
  end

  def ensure_correct_user
    @post = Post.find_by(id: params[:id])
    if @post.user_id != current_user.id
      flash[:notice] = "権限がありません"
      redirect_to("/")
    end
  end

  private
    def create_params
      params.require(:post).permit(:title, :body).merge(user_id: current_user.id)
    end
end
