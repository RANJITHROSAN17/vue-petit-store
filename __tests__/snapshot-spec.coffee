{ mount, createLocalVue } = require '@vue/test-utils'
localVue = createLocalVue()
Vuex = require 'vuex'
VueRouter = require 'vue-router'

live = require "~/../giji-fire-new/config/live.yml"
firebase = require "firebase"
require 'firebase/firestore'
firebase.initializeApp live.firebase

{ poll } = require "../lib/index.min"

localVue.use Vuex
localVue.use VueRouter

component = require './index-spec.vue'
router = new VueRouter
  mode: 'history'
  routes: [{
    name: "test"
    path: "/"
    component
  }]
router.push
  name: "test"
  params: {}

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
        test: ->
      actions: {
        ...poll.caches "1s",
          poll_test: -> "https://test.code"
      }
        

describe "", =>
  test 'snapshot', =>
    wrapper = mount component, { localVue, router, store }
    { vm } = wrapper

    # base state
    map = ( vm[c] for c in "abcdefghij" )
    expect( map ).toMatchSnapshot()
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

    map = ( vm[c] for c in "abcdefghij" )
    expect( map ).toMatchSnapshot()
    expect( wrapper.html() ).toMatchSnapshot()
    expect( location.pathname ).toEqual "/"
    expect( location.search ).toEqual "?c=f&d=e&e=d&f=c"
    expect( location.hash ).toEqual ""
    expect( document.cookie ).toEqual "i=h"
    expect( sessionStorage.getItem "g" ).toEqual "j"
    expect( localStorage.getItem "h" ).toEqual "i"
  undefined