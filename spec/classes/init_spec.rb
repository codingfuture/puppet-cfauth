require 'spec_helper'
describe 'cfauth' do

  context 'with defaults for all parameters' do
    it { should contain_class('cfauth') }
  end
end
