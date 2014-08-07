require 'spec_helper'

feature "creating workflows" do
  let(:user) { TestUser.new }
  scenario "user can create new workflow from list" do
    user.create_workflow("TestWorkflow")

    header = page.find('h1.workflow-title')
    expect(header).to have_content 'TestWorkflow'
  end
end

feature "deleting workflows" do
  before :each do
    user.create_workflow("TestWorkflow")
  end

  scenario "user can delete workflow from workflow view" do
    user.delete_workflow("TestWorkflow")

    table = page.find("table.workflows")
    expect(table).to_not have_content("TestWorkflow")
  end
end

feature "starting workflows" do
  before :each do
    user.create_workflow("TestWorkflow")
  end

  scenario "user can start workflow from homepage" do
    user.start_workflow_from_homepage("TestWorkflow")

    row = user.find_workflow_row("TestWorkflow")
    expect(row).to have_content('Stop workflow')
  end

  scenario "user can start workflow from workflow view" do
    user.go_to_workflow("TestWorkflow")

    user.click_link_matching "a.start-workflow.success"

    button = page.find('a.start-workflow.alert')
    expect(button).to have_content("Stop workflow")
  end
end

feature "stopping workflows" do
  before :each do
    user.create_workflow("TestWorkflow")
    user.start_workflow_from_homepage("TestWorkflow")
  end

  scenario "user stops workflow from homepage" do
    user.stop_workflow_from_homepage("TestWorkflow")

    row = user.find_workflow_row("TestWorkflow")
    expect(row).to have_content('Start workflow')
  end

  scenario "user stops workflow from workflow view" do
    user.go_to_workflow("TestWorkflow")
    user.click_link_matching "a.start-workflow.alert"

    button = page.find('a.start-workflow.success')
    expect(button).to have_content("Start workflow")
  end
end
