{ mount } = require '@vue/test-utils'
Vue = require 'vue'
Vuex = require 'vuex'
Vue.use Vuex

component = require './index-spec.vue'

store = new Vuex.Store
  modules:
    index:
      state:
        a: "a"
        b: "b"
      mutations:
        swap: (state)->
          [state.b, state.a] = [state.a, state.b]


describe "pushState", =>
  test 'snapshot', =>
    vm = mount component, { store }
    expect( vm.html() ).toMatchSnapshot()
    store.commit 'index/swap'
    return
    expect( vm.html() ).toMatchSnapshot()
