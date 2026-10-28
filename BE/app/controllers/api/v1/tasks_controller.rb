module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: %i[update destroy]

      # GET /api/v1/tasks
      def index
        render json: TaskBlueprint.render(current_user.tasks.order(:created_at), root: :tasks)
      end

      # POST /api/v1/tasks
      def create
        task = current_user.tasks.create!(task_params)
        render json: TaskBlueprint.render(task, root: :task), status: :created
      end

      # PATCH /api/v1/tasks/:id
      def update
        @task.update!(task_params)
        render json: TaskBlueprint.render(@task, root: :task)
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy!
        head :no_content
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:title, :description, :priority, :status, :due_at, :reminder_at)
      end
    end
  end
end
