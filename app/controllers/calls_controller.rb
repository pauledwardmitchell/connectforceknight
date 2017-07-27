class CallsController < ApplicationController

  def index

    Call.big_one_auth

  end

end
