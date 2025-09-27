require 'rails_helper'

RSpec.describe RefreshDashboardStatsJob, type: :job do
  it 'calls DashboardStat.refresh!' do
    expect(DashboardStat).to receive(:refresh!)
    described_class.perform_now
  end

  it 'logs and raises on error' do
    allow(DashboardStat).to receive(:refresh!).and_raise(StandardError.new('boom'))
    expect { described_class.perform_now }.to raise_error(StandardError, /boom/)
  end
end
