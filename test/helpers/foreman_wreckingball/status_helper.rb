# frozen_string_literal: true

module ForemanWreckingball
  module StatusHelper
    def assert_statuses(expected)
      actual = request.env['action_controller.instance'].instance_variable_get('@statuses')
      assert_same_elements expected, actual
    end
  end
end
