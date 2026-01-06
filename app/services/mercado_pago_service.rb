# frozen_string_literal: true

"""
Mercado Pago integration removed.

This file previously provided a wrapper around the Mercado Pago SDK.
To avoid leaving runtime exceptions in the codebase we keep a small marker
file here. Remove this file if you want it deleted entirely.

Payments are now expected to be handled via the payment provider panel and
the frontend. The backend does not call Mercado Pago APIs.
"""
