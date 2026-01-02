# frozen_string_literal: true

# Serviços relacionados a pacientes
module Patients
  class PatientsService
    def self.list(company_id, params = {})
      raise ArgumentError, 'company_id required' unless company_id

      query = { company_id: company_id }

      query[:status] = params[:status] if params[:status]

      if params[:search]
        search_value = params[:search].to_s
        clean_search = search_value.gsub(/\D/, '')

        if clean_search.length >= 10
          cpf_regex = clean_search.chars.join('[.-]?')
          search_term = /#{cpf_regex}/i
        else
          search_term = /#{Regexp.escape(search_value)}/i
        end

        query['$or'] = [
          { name: search_term },
          { email: search_term },
          { phone: search_term },
          { cpf: search_term }
        ]
      end

      patients = Patient.where(query).order_by(created_at: :desc)

      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      total = patients.count
      patients = patients.skip((page - 1) * per_page).limit(per_page)

      patients_data = patients.map { |p| patient_summary_hash(p) }

      {
        status: 'success',
        total: total,
        page: page,
        per_page: per_page,
        total_pages: (total.to_f / per_page).ceil,
        patients: patients_data
      }
    end

    def self.find_by_cpf(company_id, cpf)
      raise ArgumentError, 'company_id required' unless company_id

      clean_cpf = cpf.to_s.gsub(/\D/, '')
      Patient.where(company_id: company_id, cpf: /#{clean_cpf}/).first
    end

    def self.find(company_id, id)
      patient = Patient.find(id)
      if company_id && patient.company_id.to_s != company_id.to_s
        raise Mongoid::Errors::DocumentNotFound.new(Patient,
                                                    id)
      end

      patient
    end

    def self.create(company_id, params_data)
      raise ArgumentError, 'company_id required' unless company_id

      patient = Patient.new(
        company_id: company_id,
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        rg: params_data['rg'],
        birth_date: params_data['birth_date'],
        gender: params_data['gender'],
        address: params_data['address'] || {},
        blood_type: params_data['blood_type'],
        allergies: params_data['allergies'] || [],
        medications: params_data['medications'] || [],
        health_insurance: params_data['health_insurance'] || {},
        emergency_contact: params_data['emergency_contact'] || {},
        notes: params_data['notes'],
        source: params_data['source'] || 'manual'
      )

      raise StandardError, patient.errors.full_messages.join(', ') unless patient.save

      patient
    end

    def self.update(company_id, id, params_data)
      patient = find(company_id, id)

      allowed_fields = %w[
        name email phone cpf rg birth_date gender
        address blood_type allergies medications
        health_insurance emergency_contact status notes
      ]

      update_data = params_data.select { |k, _| allowed_fields.include?(k) }
      raise ArgumentError, 'Nenhum campo válido para atualizar' if update_data.empty?

      raise StandardError, patient.errors.full_messages.join(', ') unless patient.update(update_data)

      patient
    end

    def self.delete(company_id, id)
      patient = find(company_id, id)

      medical_count = patient.medical_records.count
      appointments_count = patient.appointments.count

      if medical_count.positive? || appointments_count.positive?
        raise StandardError,
              "Não é possível deletar paciente com histórico; medical_records=#{medical_count}; appointments=#{appointments_count}"
      end

      patient.delete
      true
    end

    def self.history(company_id, id)
      patient = find(company_id, id)

      appointments = patient.appointments.order_by(date: :desc).limit(50)
      medical_records = patient.medical_records.order_by(date: :desc).limit(50)

      {
        status: 'success',
        patient: { id: patient.id.to_s, name: patient.name, age: patient.age },
        appointments: appointments.map { |a| appointment_summary(a) },
        medical_records: medical_records.map { |mr| medical_record_summary(mr) }
      }
    end

    def self.patient_summary_hash(patient)
      {
        id: patient.id.to_s,
        name: patient.name,
        email: patient.email,
        phone: patient.phone,
        cpf: patient.cpf,
        birth_date: patient.birth_date,
        age: patient.age,
        gender: patient.gender,
        status: patient.status,
        company_id: patient.company_id.to_s,
        total_appointments: patient.total_appointments,
        last_appointment: patient.last_appointment&.date,
        created_at: patient.created_at
      }
    end

    def self.patient_detailed_hash(patient)
      {
        id: patient.id.to_s,
        company_id: patient.company_id.to_s,
        name: patient.name,
        email: patient.email,
        phone: patient.phone,
        cpf: patient.cpf,
        rg: patient.rg,
        birth_date: patient.birth_date,
        age: patient.age,
        gender: patient.gender,
        address: patient.address,
        blood_type: patient.blood_type,
        allergies: patient.allergies,
        medications: patient.medications,
        health_insurance: patient.health_insurance,
        emergency_contact: patient.emergency_contact,
        status: patient.status,
        notes: patient.notes,
        source: patient.source,
        total_appointments: patient.total_appointments,
        last_appointment: patient.last_appointment&.date,
        created_at: patient.created_at,
        updated_at: patient.updated_at
      }
    end

    def self.appointment_summary(appointment)
      {
        id: appointment.id.to_s,
        date: appointment.date,
        time: appointment.time,
        status: appointment.status,
        procedure: appointment.procedure
      }
    end

    def self.medical_record_summary(record)
      {
        id: record.id.to_s,
        date: record.date,
        time: record.time,
        record_type: record.record_type,
        chief_complaint: record.chief_complaint,
        professional: record.professional_name
      }
    end
  end
end
