{ mount, createLocalVue } = require '@vue/test-utils'
localVue = createLocalVue()
Vuex = require 'vuex'
VueRouter = require 'vue-router'

localVue.use Vuex
localVue.use VueRouter

component = require './index-spec.vue'
router = new VueRouter
  mode: 'history'
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
    expect( wrapper.html() ).toMatchSnapshot()

    # vuex swap
    store.commit 'index/swap'
    expect([vm.a, vm.b]).toEqual ["b","a"]

    # vuex update
    wrapper2 = mount component, { localVue, router, store }
    wrapper2.vm.a = "A"
    expect(vm.a).toEqual "A"

    # state swap
    vm.swap()
    expect( location.hash ).toEqual ""
    expect( location.pathname ).toEqual "/"
    expect( location.search ).toEqual "?c=f&d=e&e=d&f=c"
    expect( document.cookie ).toEqual "i=h"
    expect( sessionStorage.getItem "g" ).toEqual "j"
    expect( localStorage.getItem "h" ).toEqual "i"

    # finish state
    expect( wrapper.html() ).toMatchSnapshot()
