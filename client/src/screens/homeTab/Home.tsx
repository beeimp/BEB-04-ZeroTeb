import * as React from 'react'
import { useState, useEffect } from 'react'
import {
  View,
  StyleSheet,
  StatusBar,
  Platform,
  Pressable,
  FlatList,
} from 'react-native'
import Banner from '../../components/home/Banner'
import LocationButton from '../../components/location/LocationButton'
import Title from '../../components/common/Title'
import SearchBar from '../../components/search/Searchbar'
import EventList from '../../components/event/EventList'
import DummyDate from '../../data/DummyData.json'
import axios, { AxiosRequestConfig } from 'axios'
import { EventType } from '../../models/Event'
import { useNavigation } from '@react-navigation/native'

const STATUSBAR_HEIGHT = Platform.OS === 'ios' ? 40 : StatusBar.currentHeight

export default function Home() {
  const navigation = useNavigation()

  const [list, setList] = useState<EventType[]>([...DummyDate.event])

  const getEventList = async () => {
    try {
      const config: AxiosRequestConfig = {
        method: 'get',
        // url: 'http://localhost:8080/event/list?page=2&count=5',
        url: 'http://f82ebb62-8f0d-4fdf-b843-4bf1034e484e.mock.pstmn.io/event/list?page=2&count=5',
        withCredentials: true,
      }
      const res = await axios(config)
      setList(res.data)
    } catch (err) {
      alert(err)
    }
  }

  useEffect(() => {
    getEventList()
  }, [])

  return (
    <View style={style.homeContainer}>
      <LocationButton />
      <FlatList
        data={['0']}
        renderItem={() => 
          <>
            <View>
              <Title title={'찾았다 내 취향 💕'} size={22} />
              <Title title={'ZeroTeb에서 발견!'} size={22} />
              <Banner eventList={list} />
              <Pressable //입력창 누르면 Search tab으로 이동
                onPressIn={() => navigation.navigate('SearchStackScreen')}
              >
              <SearchBar
                editable={false} //터치했을때 키보드 안나오게
              />
              </Pressable>
            </View>
            <View>
              <Title title={'다가오는 공연1'} size={17} />
              <EventList eventList={list} />
            </View>
          </>
        }
      />      
    </View>
  )
}

const style = StyleSheet.create({
  homeContainer: {
    flex: 1,
    alignItems: 'flex-start',
    backgroundColor: 'white',
    marginTop: STATUSBAR_HEIGHT,
  },
})
