#!/bin/bash
cd /home/jsilva/fisio/fisio_back
export PATH="/usr/local/bin:$PATH"
source ~/.bashrc 2>/dev/null || true

# Executa o job
bundle exec ruby -r ./config/environment.rb -r ./app/jobs/check_overdue_payments.rb -e "CheckOverduePayments.run"
