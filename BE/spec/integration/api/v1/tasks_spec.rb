require "swagger_helper"

RSpec.describe "Tasks API" do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.auth_token}" }
  let(:task_record) { create(:task, user: user) }

  path "/api/v1/tasks" do
    get "List tasks" do
      tags "Tasks"
      security [{ bearer: [] }]
      produces "application/json"

      response "200", "tasks" do
        schema type: :object,
               properties: { tasks: { type: :array, items: { "$ref" => "#/components/schemas/Task" } } },
               required: ["tasks"]
        before { task_record }

        run_test!
      end
    end

    post "Create a task" do
      tags "Tasks"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/TaskInput" }

      response "201", "created" do
        schema type: :object, properties: { task: { "$ref" => "#/components/schemas/Task" } }, required: ["task"]
        let(:body) { { task: { title: "Send report", priority: "high", due_at: 1.day.from_now.iso8601 } } }

        run_test!
      end

      response "422", "invalid task" do
        schema "$ref" => "#/components/schemas/Error"
        let(:body) { { task: { title: "", priority: "whenever" } } }

        run_test!
      end
    end
  end

  path "/api/v1/tasks/{id}" do
    parameter name: :id, in: :path, type: :integer
    let(:id) { task_record.id }

    patch "Update a task (status `done` sets completed_at)" do
      tags "Tasks"
      security [{ bearer: [] }]
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/TaskInput" }

      response "200", "updated" do
        schema type: :object, properties: { task: { "$ref" => "#/components/schemas/Task" } }, required: ["task"]
        let(:body) { { task: { status: "done" } } }

        run_test!
      end
    end

    delete "Delete a task" do
      tags "Tasks"
      security [{ bearer: [] }]

      response "204", "deleted" do
        run_test!
      end
    end
  end
end
