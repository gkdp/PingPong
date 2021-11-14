// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import Alpine from 'alpinejs'
import collapse from '@alpinejs/collapse'
import sparkline from '@fnando/sparkline'
import topbar from '../vendor/topbar'

Alpine.plugin(collapse)

window.Alpine = Alpine
Alpine.start()

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')

let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    },
  },
})

function findClosest(target, tagName) {
  if (target.tagName === tagName) {
    return target
  }

  while ((target = target.parentNode)) {
    if (target.tagName === tagName) {
      break
    }
  }

  return target
}

Alpine.directive('sparkline', (el, { expression }, { evaluate }) => {
  sparkline(el, evaluate(expression), {
    onmousemove(event, datapoint) {
      var svg = findClosest(event.target, 'svg')
      var tooltip = svg.parentNode.parentNode.nextElementSibling

      tooltip.hidden = false
      tooltip.textContent = `${datapoint.original} ELO`
      tooltip.style.top = `${event.pageY}px`
      tooltip.style.left = `${event.pageX + 20}px`
    },

    onmouseout() {
      var svg = findClosest(event.target, 'svg')
      var tooltip = svg.parentNode.parentNode.nextElementSibling

      tooltip.hidden = true
    },
  })
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', (info) => topbar.show())
window.addEventListener('phx:page-loading-stop', (info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
