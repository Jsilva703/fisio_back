# frozen_string_literal: true

# Serviços relacionados a prontuários
module MedicalRecords
  class MedicalRecordsService
    def self.list_by_patient(company_id, patient_id)
      raise ArgumentError, 'patient_id required' unless patient_id

      patient = Patient.find(patient_id)
      if company_id && patient.company_id.to_s != company_id.to_s
        raise Mongoid::Errors::DocumentNotFound.new(Patient, patient_id)
      end

      records = patient.medical_records.order_by(date: :desc, created_at: :desc)
      records.map { |r| record_summary_hash(r) }
    end

    def self.find(company_id, id)
      record = MedicalRecord.find(id)
      if company_id && record.company_id.to_s != company_id.to_s
        raise Mongoid::Errors::DocumentNotFound.new(MedicalRecord, id)
      end

      record
    end

    def self.create(current_user_id, params_data)
      raise ArgumentError, 'patient_id is required' if params_data['patient_id'].to_s.strip.empty?

      patient = Patient.find(params_data['patient_id'])

      record = MedicalRecord.new(
        patient_id: patient.id,
        company_id: patient.company_id,
        created_by_id: current_user_id,
        record_type: params_data['record_type'] || 'evolution',
        date: params_data['date'],
        time: params_data['time'],
        chief_complaint: params_data['chief_complaint'],
        history: params_data['history'],
        physical_exam: params_data['physical_exam'],
        diagnosis: params_data['diagnosis'],
        treatment_plan: params_data['treatment_plan'],
        evolution: params_data['evolution'],
        procedures: params_data['procedures'] || [],
        vital_signs: params_data['vital_signs'] || {},
        tests: params_data['tests'] || [],
        pain_scale: params_data['pain_scale'],
        goals: params_data['goals'] || [],
        next_steps: params_data['next_steps'],
        attachments: params_data['attachments'] || [],
        notes: params_data['notes'],
        appointment_id: params_data['appointment_id']
      )

      raise StandardError, record.errors.full_messages.join(', ') unless record.save

      record
    end

    def self.update(company_id, id, params_data)
      record = find(company_id, id)

      allowed_fields = %w[
        record_type date time chief_complaint history
        physical_exam diagnosis treatment_plan evolution
        procedures vital_signs tests pain_scale goals
        next_steps attachments status notes
      ]

      update_data = params_data.select { |k, _| allowed_fields.include?(k) }
      raise ArgumentError, 'Nenhum campo válido para atualizar' if update_data.empty?

      raise StandardError, record.errors.full_messages.join(', ') unless record.update(update_data)

      record
    end

    def self.delete(current_user_role, current_user_id, company_id, id)
      record = find(company_id, id)

      unless current_user_role == 'machine' || record.created_by_id.to_s == current_user_id
        raise StandardError, 'Apenas o criador do prontuário ou machine pode deletá-lo'
      end

      record.delete
      true
    end

    def self.list(company_id, params = {})
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i

      query = {}
      query[:company_id] = company_id if company_id

      records = MedicalRecord.where(query)
                             .skip((page - 1) * per_page)
                             .limit(per_page)
                             .desc(:created_at)

      {
        status: 'success',
        prontuarios: records,
        page: page,
        per_page: per_page,
        total: records.count
      }
    end

    def self.period(company_id, start_date, end_date, machine_role: false, machine_company_id: nil)
      raise ArgumentError, 'start_date and end_date required' unless start_date && end_date

      query = { date: { '$gte' => start_date, '$lte' => end_date } }
      if machine_role
        query[:company_id] = machine_company_id if machine_company_id
      else
        query[:company_id] = company_id
      end

      records = MedicalRecord.where(query).order_by(date: :desc)

      records.map do |record|
        {
          id: record.id.to_s,
          patient_name: record.patient.name,
          patient_id: record.patient_id.to_s,
          date: record.date,
          time: record.time,
          record_type: record.record_type,
          chief_complaint: record.chief_complaint,
          professional: record.professional_name
        }
      end
    end

    def self.record_summary_hash(record)
      {
        id: record.id.to_s,
        date: record.date,
        time: record.time,
        record_type: record.record_type,
        chief_complaint: record.chief_complaint,
        diagnosis: record.diagnosis,
        pain_scale: record.pain_scale,
        status: record.status,
        professional: record.professional_name,
        created_by_id: record.created_by_id&.to_s,
        created_at: record.created_at,
        is_recent: record.is_recent?
      }
    end
  end
end
