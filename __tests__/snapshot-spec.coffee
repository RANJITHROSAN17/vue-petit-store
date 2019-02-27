{ mount, createLocalVue } = require '@vue/test-utils'
localVue = createLocalVue()
Vuex = require 'vuex'
VueRouter = require 'vue-router'

localVue.use Vuex
localVue.use VueRouter

component = require './index-spec.vue'
router = new VueRouter()
store = new Vuex.Store
  modules:
    index:
      namespaced: true
      state:
        a: "a"
        b: "b"
      mutations:
        update: (state, o)->
          Object.assign state, o
        swap: (state)->
          [state.b, state.a] = [state.a, state.b]

describe "pushState", =>
  test 'snapshot', =>
    wrapper = mount component, { localVue, router, store }
    { vm } = wrapper
    # base state
    expect( vm.$route ).toMatchSnapshot()
    expect( wrapper.html() ).toMatchSnapshot()

    # vuex swap
    store.commit 'index/swap'
    expect( wrapper.html() ).toMatchSnapshot()

    # vuex update
    vm.a = "local_changed_a"
    expect( wrapper.html() ).toMatchSnapshot()

    # state swap
    vm.swap()
    expect( vm.$route ).toMatchSnapshot()
    expect( wrapper.html() ).toMatchSnapshot()
