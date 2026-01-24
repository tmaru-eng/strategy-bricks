import React from 'react'
import Form from '@rjsf/core'
import validator from '@rjsf/validator-ajv8'

type FormGeneratorProps = {
  schema: Record<string, unknown>
  formData: Record<string, unknown>
  onChange: (data: Record<string, unknown>) => void
}

const buildUiSchema = (schema: Record<string, unknown>): Record<string, unknown> => {
  const uiSchema: Record<string, unknown> = {}
  const properties = schema.properties as Record<string, any> | undefined

  if (!properties) {
    return uiSchema
  }

  Object.entries(properties).forEach(([key, value]) => {
    if (!value?.ui?.control) return

    switch (value.ui.control) {
      case 'number':
        uiSchema[key] = { 'ui:widget': 'updown' }
        break
      case 'select':
        uiSchema[key] = { 'ui:widget': 'select' }
        break
      case 'checkbox':
        uiSchema[key] = { 'ui:widget': 'checkbox' }
        break
      default:
        break
    }
  })

  return uiSchema
}

export const FormGenerator: React.FC<FormGeneratorProps> = ({ schema, formData, onChange }) => {
  return (
    <Form
      schema={schema}
      uiSchema={buildUiSchema(schema)}
      formData={formData}
      validator={validator}
      onChange={({ formData: nextData }) => onChange(nextData as Record<string, unknown>)}
    >
      <div />
    </Form>
  )
}
