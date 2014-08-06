class TestUser
  include Capybara::DSL

  def visit_homepage
    visit '/'
  end

  def create_workflow(name)
    visit_homepage
    click_on "Create workflow"
    click_on name
  end

  def click_link_matching(css)
    page.find(css).trigger('click')
    wait_for_ajax
  end

  def go_to_workflow(name)
    visit_homepage
    click_link_matching("table.workflows tr[data-name=\"#{name}\"] a[href*=show]")
  end

  def delete_workflow(name)
    go_to_workflow(name)

    page.find('a.start-workflow span').trigger('click') # opens popup
    click_on "Delete workflow"
  end

  def start_workflow_from_homepage(name)
    visit_homepage
    click_link_matching("table.workflows tr[data-name=\"#{name}\"] a.start-workflow.success")
  end

  def stop_workflow_from_homepage(name)
    visit_homepage
    click_link_matching("table.workflows tr[data-name=\"#{name}\"] a.start-workflow.alert")
  end

  def reload_page
    visit current_url
  end

  def screenshot
    save_screenshot(Pathname.pwd + "#{Time.now}.png")
  end

  def find_workflow_row(name)
    page.find("table.workflows tr[data-name=\"#{name}\"]")
  end

  private
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
  end
end
