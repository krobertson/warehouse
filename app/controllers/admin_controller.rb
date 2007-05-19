class AdminController < ApplicationController
  def index
    @repos = Repository.find(:all)
  end
end
