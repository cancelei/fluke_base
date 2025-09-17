require 'rails_helper'

RSpec.describe AgreementCalculationsService do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, project: project, initiator: alice, other_party: bob) }
  let(:service) { described_class.new(agreement) }

  describe "initialization" do
    it "accepts an agreement object" do
      expect(service.instance_variable_get(:@agreement)).to eq(agreement)
    end
  end

  describe "#duration_in_weeks" do
    it "calculates duration between start and end dates" do
      agreement.update!(
        start_date: Date.current,
        end_date: 4.weeks.from_now.to_date
      )

      expect(service.duration_in_weeks).to eq(4)
    end

    it "handles partial weeks" do
      agreement.update!(
        start_date: Date.current,
        end_date: 3.5.weeks.from_now.to_date
      )

      # Should round to nearest week or handle fractional weeks
      duration = service.duration_in_weeks
      expect(duration).to be_between(3, 4)
    end

    it "returns zero for same-day agreements" do
      same_date = Date.current
      agreement.update!(
        start_date: same_date,
        end_date: same_date
      )

      expect(service.duration_in_weeks).to eq(0)
    end
  end

  describe "#total_cost" do
    context "for hourly payment agreements" do
      before do
        agreement.update!(
          payment_type: Agreement::HOURLY,
          start_date: Date.current,
          end_date: 4.weeks.from_now.to_date,
          weekly_hours: 10,
          hourly_rate: 50.0
        )
      end

      it "calculates total cost correctly" do
        expected_cost = 4 * 10 * 50.0  # 4 weeks * 10 hours/week * $50/hour
        expect(service.total_cost).to eq(expected_cost)
      end

      it "handles zero hourly rate" do
        agreement.update!(hourly_rate: 0)
        expect(service.total_cost).to eq(0)
      end

      it "handles decimal hourly rates" do
        agreement.update!(hourly_rate: 37.5)
        expected_cost = 4 * 10 * 37.5
        expect(service.total_cost).to eq(expected_cost)
      end
    end

    context "for equity payment agreements" do
      before do
        agreement.update!(
          payment_type: Agreement::EQUITY,
          equity_percentage: 15.0,
          hourly_rate: nil
        )
      end

      it "returns zero for equity-only agreements" do
        expect(service.total_cost).to eq(0)
      end

      it "includes note about equity in payment details" do
        details = service.payment_details
        expect(details).to include("equity")
      end
    end

    context "for hybrid payment agreements" do
      before do
        agreement.update!(
          payment_type: Agreement::HYBRID,
          start_date: Date.current,
          end_date: 4.weeks.from_now.to_date,
          weekly_hours: 10,
          hourly_rate: 30.0,
          equity_percentage: 10.0
        )
      end

      it "calculates hourly portion of hybrid agreements" do
        expected_hourly_cost = 4 * 10 * 30.0  # Only hourly component
        expect(service.total_cost).to eq(expected_hourly_cost)
      end

      it "includes both hourly and equity in payment details" do
        details = service.payment_details
        expect(details).to include("$30.0")
        expect(details).to include("10.0%")
      end
    end
  end

  describe "#payment_details" do
    it "formats hourly payment details" do
      agreement.update!(
        payment_type: Agreement::HOURLY,
        hourly_rate: 75.0,
        weekly_hours: 10
      )

      details = service.payment_details
      expect(details).to include("$75.0")
      expect(details).to include("hour")
      expect(details).to include("10")
    end

    it "formats equity payment details" do
      agreement.update!(
        payment_type: Agreement::EQUITY,
        equity_percentage: 15.0
      )

      details = service.payment_details
      expect(details).to include("15.0%")
      expect(details).to include("equity")
    end

    it "formats hybrid payment details" do
      agreement.update!(
        payment_type: Agreement::HYBRID,
        hourly_rate: 40.0,
        equity_percentage: 12.0,
        weekly_hours: 15
      )

      details = service.payment_details
      expect(details).to include("$40.0")
      expect(details).to include("12.0%")
      expect(details).to include("15")
    end
  end

  describe "#total_hours_logged" do
    let(:milestone1) { create(:milestone, project: project) }
    let(:milestone2) { create(:milestone, project: project) }

    before do
      agreement.update!(milestone_ids: [ milestone1.id, milestone2.id ])
    end

    context "without context user" do
      it "returns total hours from all participants" do
        # Create time logs for both users
        create(:time_log, project: project, milestone: milestone1, user: alice, hours: 5)
        create(:time_log, project: project, milestone: milestone1, user: bob, hours: 3)
        create(:time_log, project: project, milestone: milestone2, user: alice, hours: 2)

        total_hours = service.total_hours_logged
        expect(total_hours).to eq(10)  # 5 + 3 + 2
      end

      it "only counts hours for agreement milestones" do
        other_milestone = create(:milestone, project: project)

        create(:time_log, project: project, milestone: milestone1, user: alice, hours: 5)
        create(:time_log, project: project, milestone: other_milestone, user: alice, hours: 10)

        total_hours = service.total_hours_logged
        expect(total_hours).to eq(5)  # Only milestone1 is in the agreement
      end
    end

    context "with context user" do
      it "returns hours logged by specific user" do
        create(:time_log, project: project, milestone: milestone1, user: alice, hours: 5)
        create(:time_log, project: project, milestone: milestone1, user: bob, hours: 3)
        create(:time_log, project: project, milestone: milestone2, user: alice, hours: 2)

        alice_hours = service.total_hours_logged(alice)
        expect(alice_hours).to eq(7)  # 5 + 2

        bob_hours = service.total_hours_logged(bob)
        expect(bob_hours).to eq(3)
      end

      it "returns zero for user with no logged hours" do
        charlie = create(:user)
        create(:time_log, project: project, milestone: milestone1, user: alice, hours: 5)

        charlie_hours = service.total_hours_logged(charlie)
        expect(charlie_hours).to eq(0)
      end
    end

    it "handles agreements with no milestones" do
      agreement.update!(milestone_ids: [])
      total_hours = service.total_hours_logged
      expect(total_hours).to eq(0)
    end
  end

  describe "#current_time_log" do
    let(:milestone) { create(:milestone, project: project) }

    before do
      agreement.update!(milestone_ids: [ milestone.id ])
    end

    it "returns nil when no active time logs exist" do
      expect(service.current_time_log).to be_nil
    end

    it "finds currently active time log for agreement participants" do
      # Create an active time log (end_time is nil)
      active_log = create(:time_log,
        project: project,
        milestone: milestone,
        user: alice,
        start_time: 1.hour.ago,
        end_time: nil
      )

      expect(service.current_time_log).to eq(active_log)
    end

    it "ignores completed time logs" do
      create(:time_log,
        project: project,
        milestone: milestone,
        user: alice,
        start_time: 2.hours.ago,
        end_time: 1.hour.ago
      )

      expect(service.current_time_log).to be_nil
    end

    it "prioritizes most recent active log" do
      older_log = create(:time_log,
        project: project,
        milestone: milestone,
        user: alice,
        start_time: 2.hours.ago,
        end_time: nil
      )

      newer_log = create(:time_log,
        project: project,
        milestone: milestone,
        user: bob,
        start_time: 1.hour.ago,
        end_time: nil
      )

      expect(service.current_time_log).to eq(newer_log)
    end
  end

  describe "edge cases and error handling" do
    it "handles nil dates gracefully" do
      agreement.update!(start_date: nil, end_date: nil)

      expect(service.duration_in_weeks).to eq(0)
      expect(service.total_cost).to eq(0)
    end

    it "handles agreements with zero weekly hours" do
      agreement.update!(
        weekly_hours: 0,
        hourly_rate: 50.0,
        start_date: Date.current,
        end_date: 4.weeks.from_now.to_date
      )

      expect(service.total_cost).to eq(0)
    end

    it "handles very large numbers" do
      agreement.update!(
        weekly_hours: 40,
        hourly_rate: 999.99,
        start_date: Date.current,
        end_date: 52.weeks.from_now.to_date
      )

      # Should not raise overflow errors
      expect { service.total_cost }.not_to raise_error
      expect(service.total_cost).to be > 0
    end
  end

  describe "integration with agreement model" do
    it "delegates calculations from agreement model" do
      expect(service).to receive(:total_cost).and_return(1000.0)
      agreement.calculate_total_cost
    end

    it "maintains consistency with agreement attributes" do
      agreement.update!(
        payment_type: Agreement::HOURLY,
        weekly_hours: 20,
        hourly_rate: 60.0,
        start_date: Date.current,
        end_date: 8.weeks.from_now.to_date
      )

      expected_cost = 8 * 20 * 60.0
      expect(service.total_cost).to eq(expected_cost)
      expect(agreement.calculate_total_cost).to eq(expected_cost)
    end
  end

  describe "performance considerations" do
    it "efficiently calculates with many time logs" do
      milestone = create(:milestone, project: project)
      agreement.update!(milestone_ids: [ milestone.id ])

      # Create many time logs
      50.times do |i|
        create(:time_log,
          project: project,
          milestone: milestone,
          user: [ alice, bob ].sample,
          hours: rand(1..8)
        )
      end

      expect { service.total_hours_logged }.not_to raise_error
    end
  end
end
