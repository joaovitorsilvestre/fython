export default {
  topics: [
    { name: 'installation', pages: [], ref: 'installation', text: 'como instalar' },
    {
      name: 'introduction',
      ref: 'introduction',
      text: 'introduzindo',
      pages: [
        {
          name: 'What is Fython',
          ref: 'introduction.WhatisFython',
          text: 'Some markdown text',
          pages: [
            { name: 'installation', pages: [], ref: 'introduction.WhatisFython.installation', text: 'como instalar' }
          ]
        }
      ]
    },
    { name: 'modules', pages: [], ref: 'modules', text: 'esses são os modulos' }
  ]
}
