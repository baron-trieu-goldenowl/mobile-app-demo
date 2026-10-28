module Api
  module V1
    class BaseController < ApplicationController
      include ErrorRendering
      include Authenticatable
    end
  end
end
