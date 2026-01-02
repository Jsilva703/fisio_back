# frozen_string_literal: true

# Serviço responsável pela lógica do dashboard de máquinas
module Machine
  class MachineDashboardService
    def self.dashboard_stats
      {
        total_companies: Company.count,
        active_companies: Company.where(status: 'active').count,
        inactive_companies: Company.where(status: 'inactive').count,
        suspended_companies: Company.where(status: 'suspended').count,
        total_users: User.where(:company_id.ne => nil).count,
        total_appointments: Appointment.count,
        total_schedulings: Scheduling.count,
        total_revenue: Appointment.all.sum { |a| a.price.to_f },
        companies_by_plan: Company.all.group_by(&:plan).transform_values(&:count),
        top_companies: Company.all.map do |company|
          {
            id: company.id.to_s,
            name: company.name,
            schedulings_count: Scheduling.where(company_id: company.id).count
          }
        end.sort_by { |c| -c[:schedulings_count] }.first(5)
      }
    end
  end
end
