class BrowserController < ApplicationController
  def index
    @revision = params[:rev][1..-1].to_i if params[:rev]
    @node     = repository.node(params[:paths] * '/', @revision)
  end
end
