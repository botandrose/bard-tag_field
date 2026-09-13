import { expect } from '@esm-bundle/chai'
import '../src/input-tag.js'
import { setupGlobalTestHooks, setupInputTag, waitForUpdate } from './lib/test-utils.js'

describe('Form state restore (Firefox session restore)', () => {
  setupGlobalTestHooks()

  it('saves the tag values as a JSON string form state, not the FormData Firefox flattens', async () => {
    const inputTag = await setupInputTag(`
      <form><input-tag name="labels[]" multiple>
        <tag-option value="urgent">urgent</tag-option>
        <tag-option value="backend">backend</tag-option>
      </input-tag></form>
    `)
    await waitForUpdate()

    const states = []
    const internals = inputTag._internals
    const real = internals.setFormValue.bind(internals)
    internals.setFormValue = (value, state) => { states.push(state); real(value, state) }

    inputTag.add('frontend')
    await waitForUpdate()

    const lastState = states[states.length - 1]
    expect(lastState).to.be.a('string')
    expect(JSON.parse(lastState)).to.eql(['urgent', 'backend', 'frontend'])
  })

  it('rebuilds the tags from a restored state string', async () => {
    const inputTag = await setupInputTag(`<form><input-tag name="labels[]" multiple></input-tag></form>`)
    await waitForUpdate()
    expect(inputTag.tags).to.eql([])

    inputTag.formStateRestoreCallback(JSON.stringify(['urgent', 'backend']))
    await waitForUpdate()

    expect(inputTag.tags).to.eql(['urgent', 'backend'])
  })

  it('falls back to the current tags when the restored state is the coerced "[object Object]"', async () => {
    const inputTag = await setupInputTag(`
      <form><input-tag name="labels[]" multiple>
        <tag-option value="keep">keep</tag-option>
      </input-tag></form>
    `)
    await waitForUpdate()

    inputTag.formStateRestoreCallback('[object Object]')
    await waitForUpdate()

    expect(inputTag.tags).to.eql(['keep'])
  })
})
