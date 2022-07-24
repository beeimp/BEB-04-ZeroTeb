import axios, { AxiosRequestConfig } from 'axios'
import * as React from 'react'
import { useEffect, useState } from 'react'
import {
  StatusBar,
  Platform,
  StyleSheet,
  Dimensions,
  ScrollView,
  View,
} from 'react-native'
import { useSelector } from 'react-redux'
import SearchList from '../../components/search/SearchList'
import { RootState } from '../../store/Index'

const STATUSBAR_HEIGHT = Platform.OS === 'ios' ? 40 : StatusBar.currentHeight
const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window')

interface Props {
  type: string
}

export default function MyList({ route }) {
  const [typeList, setTypeList] = useState([])
  const KilpAddress = useSelector(
    (state: RootState) => state.signin.KilpAddress,
  )

  console.log('props', route.params.type)
  console.log('address', KilpAddress)
  // address랑 type은 props로 받음
  //리덕스에 있는 로그인된 주소로 교환 필요

  //지금 페이지랑 카운트는 의미없음(작동 안함)
  const page = 1
  const count = 1

  //type에 따라 검색
  //entry: type data가 entry 목록 검색
  //sale: type data가 sale인 목록 검색
  //create: address데이터가 입력한 address인 목록을 검색
  //liked: 좋아요 콜렉션에 있고, 입력한 address를 가진 목록을 검색
  //http://server.beeimp.com:18080/event/history?address=0xf0a29e430d12065bfa9a5e0bc694f26accb151f4&page=1&count=5&type=created
  const getTypeListHandler = async () => {
    try {
      const config: AxiosRequestConfig = {
        method: 'get',
        url: `http://server.beeimp.com:18080/event/history?address=${KilpAddress}&page=${page}&count=${count}&type=${route.params.type}`,
        withCredentials: true,
      }
      const res = await axios(config)
      // console.log(res.data);
      if (res.data.message) {
        console.log(res.data.message)
      } else {
        setTypeList(res.data)
      }
    } catch (err) {
      alert(err)
    }
  }
  //페이지를 시작할 때, 데이터 검색
  useEffect(() => {
    getTypeListHandler()
  }, [])

  return (
    <View style={styles.container}>
      <SearchList
        sendList={typeList}
        type={route.params.type}
        address={KilpAddress}
      ></SearchList>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'white',
    flexDirection: 'column',
    width: SCREEN_WIDTH,
    height: SCREEN_HEIGHT,
  },
})