import React from 'react'

export const isFragment = e => e.type === React.Fragment
export const elementChildren = e => e.props.children
export const elementType = e => typeof e === 'string' ? 'text' : e.type
export const elementText = e =>
  typeof e === 'string' ? e :
  typeof e.props.children === 'string' ? e.props.children :
  e.props.children.map(elementText).join('|')
