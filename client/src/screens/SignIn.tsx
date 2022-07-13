import * as React from 'react'
import { useState } from 'react'
import Ionicons from '@expo/vector-icons/Ionicons'
import { View, TouchableOpacity, StyleSheet, Text, Image } from 'react-native'
import KilpImage from '../../assets/kilp_image.png'
import KilpIcon from '../../assets/kilp_icon.png'
import * as KlipAPI from '../layout/kilps/modal/WalletInfo.tsx'

const DEFAULT_ADDRESS = '0x00000000000000000000000000000'

interface SignInProps {
  setQrvalue: any
  callback: any
}

const SignIn: React.FC<SignInProps> = () => {
  const [isChecked, setisChecked] = useState(false)
  const [myAddress, setMyAddress] = useState(DEFAULT_ADDRESS)

  //지갑 연동하는 함수 실행
  const getUserData = () => {
    KlipAPI.getAddress(async (address: any) => {
      setMyAddress(address)
    })
  }

  return (
    <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
      <Image source={KilpImage} style={styles.image} />

      <TouchableOpacity style={styles.checkIcon}>
        <Ionicons
          name="checkmark-circle-outline"
          size={25}
          color={isChecked ? 'green' : 'gray'}
          onPress={() => {
            setisChecked(!isChecked)
          }}
        ></Ionicons>
      </TouchableOpacity>
      <View style={styles.checkTextBox}>
        <Text style={styles.checkText}>약관에 동의 하시겠습니까?</Text>
      </View>

      {isChecked ? (
        <TouchableOpacity style={styles.loginbutton} onPress={getUserData}>
          <Image source={KilpIcon} style={styles.icon} />
          <Text style={styles.text}>Kilp으로 로그인</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity style={styles.loginbuttonNot} disabled>
          <Image source={KilpIcon} style={styles.icon} />
          <Text style={styles.text}>Kilp으로 로그인</Text>
        </TouchableOpacity>
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  image: {
    width: 391,
    height: 296,
  },
  checkIcon: {
    right: 95,
  },
  checkTextBox: {
    left: 10,
    bottom: 24,
  },
  checkText: {
    // fontFamily: 'Itim',
    fontSize: 16,
  },
  checkbox: {
    margin: 20,
    textDecorationLine: 'none',
  },
  loginbutton: {
    flex: 1,
    flexDirection: 'row',
    width: 292,
    maxHeight: 43,
    top: 0,
    borderRadius: 4,
    backgroundColor: '#216FEA',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loginbuttonNot: {
    flex: 1,
    flexDirection: 'row',
    width: 292,
    maxHeight: 43,
    top: 0,
    borderRadius: 4,
    backgroundColor: 'gray',
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    // fontFamily: 'JetBrains Mono',
    fontSize: 18,
    color: 'white',
  },
  icon: {
    margin: 7,
  },
})

export default SignIn
