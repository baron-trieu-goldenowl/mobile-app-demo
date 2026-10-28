module Api
  module V1
    class AccountsController < BaseController
      # DELETE /api/v1/account
      # Permanently deletes the account and all data (App Store 5.1.1(v)).
      def destroy
        Accounts::Destroy.call(current_user)
        head :no_content
      end
    end
  end
end
